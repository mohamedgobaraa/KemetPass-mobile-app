from flask import Flask, request, jsonify, session, send_from_directory
from flask_cors import CORS
from werkzeug.utils import secure_filename
import os
import numpy as np
from tensorflow.keras.applications.vgg16 import VGG16, preprocess_input
from tensorflow.keras.preprocessing import image
from sklearn.metrics.pairwise import cosine_similarity
import pickle
from tensorflow.keras.models import load_model
import joblib
from groq import Groq
from database import DatabaseHandler
import sqlite3
import uuid
from datetime import datetime
import json

app = Flask(__name__)
app.secret_key = 'Key'
CORS(app, supports_credentials=True, resources={r"/*": {"origins": "*", "allow_headers": ["Content-Type", "User-ID"]}})

db = DatabaseHandler()

USERS_IMAGES_FOLDER = 'uploads/users_images'
os.makedirs(USERS_IMAGES_FOLDER, exist_ok=True)

print(f"Current working directory: {os.getcwd()}")
print(f"Uploads folder exists: {os.path.exists('uploads')}")
print(f"Users images folder exists: {os.path.exists(USERS_IMAGES_FOLDER)}")

@app.route('/uploads/<path:filename>')
def serve_uploads(filename):
    return send_from_directory('uploads', filename)

def get_full_image_url(image_path):
    if not image_path:
        return None
        
    if image_path.startswith(('http://', 'https://')):
        return image_path
        
    server_url = "http://192.168.1.4:8000"
    
    if image_path.startswith('/'):
        image_path = image_path[1:]
        
    return f"{server_url}/{image_path}"

WHERE_IM_UPLOAD_FOLDER = 'uploads/where_im'
WHO_IM_UPLOAD_FOLDER = 'uploads/who_im'

os.makedirs(WHERE_IM_UPLOAD_FOLDER, exist_ok=True)
os.makedirs(WHO_IM_UPLOAD_FOLDER, exist_ok=True)
WHERE_IM_CLIENT = Groq(api_key="API")
WHERE_IM_MODEL = VGG16(weights='imagenet', include_top=False, input_shape=(224, 224, 3))
WHO_AM_I_MODEL = VGG16(weights='imagenet', include_top=False, input_shape=(224, 224, 3))  # Separate model for Who Am I
WHERE_IM_FEATURES, WHERE_IM_LABELS, WHERE_IM_IMAGE_PATHS = None, None, None
WHO_AM_I_FEATURES, WHO_AM_I_LABELS, WHO_AM_I_IMAGE_PATHS = None, None, None

TRANSLATE_UPLOAD_FOLDER = 'uploads/translate'
os.makedirs(TRANSLATE_UPLOAD_FOLDER, exist_ok=True)
TRANSLATE_MODEL = load_model("Egyptian_hieroglyphic_Model_classification.h5")
TRANSLATE_LABEL_ENCODER = joblib.load("Egyptian_hieroglyphic_label_encoder.joblib")
TRANSLATE_CLIENT = Groq(api_key="API")

CHATBOT_MEMORY = []

def load_where_im_features(feature_file="WHERE_IM_image_features.pkl"):
    global WHERE_IM_FEATURES, WHERE_IM_LABELS, WHERE_IM_IMAGE_PATHS
    try:
        with open(feature_file, "rb") as f:
            data = pickle.load(f)
        WHERE_IM_FEATURES, WHERE_IM_LABELS, WHERE_IM_IMAGE_PATHS = (
            data["features"],
            data["labels"],
            data["image_paths"],
        )
    except Exception as e:
        raise FileNotFoundError(f"Error loading Where Am I features file: {e}")

load_where_im_features("WHERE_IM_image_features.pkl")

def load_who_am_i_features(feature_file="who_im_image_features.pkl"):
    global WHO_AM_I_FEATURES, WHO_AM_I_LABELS, WHO_AM_I_IMAGE_PATHS
    try:
        with open(feature_file, "rb") as f:
            data = pickle.load(f)
        WHO_AM_I_FEATURES, WHO_AM_I_LABELS, WHO_AM_I_IMAGE_PATHS = (
            data["features"],
            data["labels"],
            data["image_paths"],
        )
        print("Who Am I features loaded successfully")
    except Exception as e:
        print(f"Error loading Who Am I features file: {e}")
        raise FileNotFoundError(f"Error loading Who Am I features file: {e}")
        
load_who_am_i_features("who_im_image_features.pkl")


def add_to_chatbot_memory(role, content):
    CHATBOT_MEMORY.append({"role": role, "content": content})
    if len(CHATBOT_MEMORY) > 50:
        CHATBOT_MEMORY.pop(0)

def preprocess_image_where_im(img_path, target_size=(224, 224)):
    img = image.load_img(img_path, target_size=target_size)
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    return preprocess_input(img_array)

def extract_where_im_features(path):
    img = preprocess_image_where_im(path, target_size=(224, 224))
    return WHERE_IM_MODEL.predict(img).flatten()

def find_most_similar_place_where_im(query_img_path):
    query_feature = extract_where_im_features(query_img_path).reshape(1, -1)
    similarities = cosine_similarity(query_feature, WHERE_IM_FEATURES)[0]
    if len(similarities) == 0:
        return "Unknown Place"
    most_similar_index = np.argmax(similarities)
    return WHERE_IM_LABELS[most_similar_index]

def preprocess_image_who_am_i(img_path, target_size=(224, 224)):
    img = image.load_img(img_path, target_size=target_size)
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    return preprocess_input(img_array)

def extract_who_am_i_features(path):
    img = preprocess_image_who_am_i(path, target_size=(224, 224))
    return WHO_AM_I_MODEL.predict(img).flatten()

def find_most_similar_person_who_am_i(query_img_path):
    query_feature = extract_who_am_i_features(query_img_path).reshape(1, -1)
    similarities = cosine_similarity(query_feature, WHO_AM_I_FEATURES)[0]
    if len(similarities) == 0:
        return "Unknown Person"
    most_similar_index = np.argmax(similarities)
    return WHO_AM_I_LABELS[most_similar_index]

def preprocess_translate_image(img_path):
    img = image.load_img(img_path, target_size=(128, 128))
    img_array = image.img_to_array(img)
    img_array = np.expand_dims(img_array, axis=0)
    img_array /= 255.0
    return img_array

def predict_translate_class(img_path):
    processed_image = preprocess_translate_image(img_path)
    predictions = TRANSLATE_MODEL.predict(processed_image)
    predicted_class_index = np.argmax(predictions, axis=1)
    return TRANSLATE_LABEL_ENCODER.inverse_transform(predicted_class_index)[0]

def generate_translate_sentence(predicted_classes):
    combined_context = ", ".join(predicted_classes)
    messages = [
        {
            "role": "system",
            "content": """
            You are an advanced AI Egyptologist at the forefront of linguistic and cultural interpretation, uniquely designed to decode
            and articulate the messages of ancient Egyptian hieroglyphics with exceptional depth and accuracy. Your role begins with
            receiving a single or multi-classification result from an image recognition model, which identifies one or more hieroglyphic
            symbols. Using this input, you are tasked with synthesizing the classified symbols into a fluent, meaningful sentence that
            reflects their literal and contextual significance. You must analyze the phonetic, symbolic, and grammatical elements of
            the hieroglyphs, reconstructing their intended message with precision. Additionally, you enrich your translation by
            integrating cultural, historical, and ceremonial context, ensuring the message resonates with its original purpose
            and tone. While your response must capture the essence and depth of the hieroglyphic message, it should remain concise
            and not overly long, delivering clarity and impact without unnecessary complexity.
            """
        },
        {"role": "user", "content": f"Context: {combined_context}"}
    ]

    request_params = {
        "model": "llama3-70b-8192",
        "messages": messages,
        "temperature": 0.7,
        "max_tokens": 64,
        "top_p": 1,
        "stream": False,
    }

    completion = TRANSLATE_CLIENT.chat.completions.create(**request_params)
    response_content = completion.choices[0].message.content

    return response_content.strip()


@app.route('/register', methods=['POST'])
def register():
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        username = data.get('username')
        firstName = data.get('firstName')
        secondName = data.get('secondName')
        
        if not email or not password:
            return jsonify({"error": "Email and password are required"}), 400
            
        print(f"Register API: username={username}, firstName={firstName}, secondName={secondName}")
            
        result = db.register_user(
            email, 
            password, 
            username,
            firstName=firstName,
            secondName=secondName
        )
        
        if result["success"]:

            user_id = result["user_id"]
            user_folder = os.path.join(USERS_IMAGES_FOLDER, str(user_id))
            os.makedirs(user_folder, exist_ok=True)
            print(f"Created user folder: {user_folder}")
            
            session['user_id'] = user_id
            
            conn = sqlite3.connect(db.db_path)
            cursor = conn.cursor()
            cursor.execute(
                'SELECT id, email, username, profile_picture, firstName, secondName, phone, country, language FROM users WHERE id = ?', 
                (user_id,)
            )
            user = cursor.fetchone()
            conn.close()
            
            if user:
                profile_picture = user[3]
                full_profile_picture_url = get_full_image_url(profile_picture) if profile_picture else ""
                
                return jsonify({
                    "success": True, 
                    "user_id": user_id,
                    "user": {
                        "id": user[0],
                        "email": user[1],
                        "username": user[2],
                        "profileImageUrl": full_profile_picture_url,
                        "firstName": user[4] or "",
                        "secondName": user[5] or "",
                        "phone": user[6] or "",
                        "country": user[7] or "Egypt",
                        "language": user[8] or "English"
                    }
                })
            
            return jsonify({"success": True, "user_id": user_id})
        else:
            return jsonify({"error": result["error"]}), 400
            
    except Exception as e:
        print(f"Register API error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/login', methods=['POST'])
def login():
    try:
        data = request.json
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({"error": "Email and password are required"}), 400
            
        result = db.login_user(email, password)
        
        if result["success"]:
            session['user_id'] = result["user"]["id"]
            return jsonify({"success": True, "user": result["user"]})
        else:
            return jsonify({"error": result["error"]}), 401
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/logout', methods=['POST'])
def logout():
    session.pop('user_id', None)
    return jsonify({"success": True})

@app.route('/update_profile', methods=['POST'])
def update_profile():
    try:

        user_id = None
        if 'user_id' in session:
            user_id = session['user_id']
        elif 'User-ID' in request.headers:
            try:
                user_id = int(request.headers['User-ID'])
            except ValueError:
                return jsonify({"error": "Invalid User-ID in header"}), 400
        elif request.json and 'userId' in request.json:
            try:
                user_id = int(request.json['userId'])
            except ValueError:
                return jsonify({"error": "Invalid userId in request body"}), 400
        elif request.form and 'userId' in request.form:
            try:
                user_id = int(request.form['userId'])
            except ValueError:
                return jsonify({"error": "Invalid userId in form data"}), 400
        
        if user_id is None:
            return jsonify({"error": "Not authenticated"}), 401
        
        is_multipart = request.content_type and 'multipart/form-data' in request.content_type
        
        if is_multipart:

            username = request.form.get('username')
            firstName = request.form.get('firstName')
            secondName = request.form.get('secondName')
            email = request.form.get('email')
            phone = request.form.get('phone')
            country = request.form.get('country')
            language = request.form.get('language')
            
            print(f"Update profile - firstName: {firstName}, secondName: {secondName}")
            
            profile_picture = None
            if 'profile_picture' in request.files:
                file = request.files['profile_picture']
                if file.filename:

                    user_folder = os.path.join(USERS_IMAGES_FOLDER, str(user_id))
                    os.makedirs(user_folder, exist_ok=True)
                    
                    filename = secure_filename(file.filename)
                    filepath = os.path.join(user_folder, filename)
                    file.save(filepath)
                    
                    profile_picture = f"/uploads/users_images/{user_id}/{filename}"
                    print(f"Uploaded profile picture to {filepath}, URL: {profile_picture}")
        else:
            data = request.json
            username = data.get('username')
            firstName = data.get('firstName')
            secondName = data.get('secondName')
            email = data.get('email')
            phone = data.get('phone')
            country = data.get('country')
            language = data.get('language')
            profile_picture = data.get('profileImageUrl')
            
            print(f"Update profile - firstName: {firstName}, secondName: {secondName}")
        
        result = db.update_user_profile(
            user_id, 
            firstName=firstName,
            secondName=secondName,
            username=username,
            email=email,
            phone=phone,
            country=country,
            language=language,
            profile_picture=profile_picture
        )
        
        if result["success"]:
            response_data = {"success": True}
            if profile_picture:
                full_profile_picture_url = get_full_image_url(profile_picture)
                response_data["profileImageUrl"] = full_profile_picture_url
                print(f"Returning full profile picture URL: {full_profile_picture_url}")
            return jsonify(response_data)
        else:
            return jsonify({"error": result["error"]}), 400
            
    except Exception as e:
        print(f"Error in update_profile: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/upload_profile_image', methods=['POST'])
def upload_profile_image():
    try:
        user_id = None
        if 'user_id' in session:
            user_id = session['user_id']
        elif 'User-ID' in request.headers:
            user_id = request.headers['User-ID']
        elif request.form and 'userId' in request.form:
            user_id = request.form['userId']
        
        if user_id is None:
            return jsonify({"error": "Not authenticated"}), 401
            
        if 'profile_picture' not in request.files:
            return jsonify({"error": "No profile picture uploaded"}), 400
            
        file = request.files['profile_picture']
        if not file.filename:
            return jsonify({"error": "No file selected"}), 400

        print(f"Uploading profile picture for user ID: {user_id}")
            
        user_folder = os.path.join(USERS_IMAGES_FOLDER, str(user_id))
        os.makedirs(user_folder, exist_ok=True)
        
        for old_file in os.listdir(user_folder):
            old_file_path = os.path.join(user_folder, old_file)
            if os.path.isfile(old_file_path):
                os.remove(old_file_path)
                print(f"Deleted old profile picture: {old_file_path}")
        
        timestamp = int(datetime.now().timestamp())
        filename = secure_filename(f"{user_id}_{timestamp}_{file.filename}")
        filepath = os.path.join(user_folder, filename)
        file.save(filepath)
        
        profile_picture_url = f"/uploads/users_images/{user_id}/{filename}"
        print(f"Uploaded profile picture to {filepath}, URL: {profile_picture_url}")
        
        full_profile_picture_url = get_full_image_url(profile_picture_url)
        print(f"Full profile picture URL: {full_profile_picture_url}")
        
        result = db.update_user_profile(user_id, profile_picture=profile_picture_url)
        
        if result["success"]:
            return jsonify({
                "success": True,
                "profileImageUrl": full_profile_picture_url
            })
        else:
            return jsonify({"error": result["error"]}), 400
            
    except Exception as e:
        print(f"Error in upload_profile_image: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/get_profile', methods=['GET'])
def get_profile():
    try:

        user_id = None
        if 'user_id' in session:
            user_id = session['user_id']
        elif 'User-ID' in request.headers:
            try:
                user_id = request.headers['User-ID']
            except ValueError:
                return jsonify({"error": "Invalid User-ID in header"}), 400
        
        if user_id is None:
            return jsonify({"error": "Not authenticated"}), 401
            
        conn = sqlite3.connect(db.db_path)
        cursor = conn.cursor()
        
        print(f"Fetching profile for user_id: {user_id}, type: {type(user_id)}")
        
        cursor.execute(
            'SELECT id, email, username, profile_picture, firstName, secondName, phone, country, language FROM users WHERE id = ?', 
            (user_id,)
        )
        
        user = cursor.fetchone()
        conn.close()
        
        if user:

            profile_picture = user[3]
            full_profile_picture_url = get_full_image_url(profile_picture) if profile_picture else ""
            
            print(f"Original profile picture path: {profile_picture}")
            print(f"Full profile picture URL: {full_profile_picture_url}")
            
            return jsonify({
                "success": True,
                "profile": {
                    "id": user[0],
                    "email": user[1],
                    "username": user[2],
                    "profileImageUrl": full_profile_picture_url,
                    "firstName": user[4] or "",
                    "secondName": user[5] or "",
                    "phone": user[6] or "",
                    "country": user[7] or "Egypt",
                    "language": user[8] or "English"
                }
            })
        else:
            print(f"No user found with id: {user_id}")
            return jsonify({"error": "User not found"}), 404
            
    except Exception as e:
        print(f"Error in get_profile: {str(e)}")
        return jsonify({"error": str(e)}), 500



@app.route('/save_item', methods=['POST'])
def save_item():
    try:
        if 'user_id' not in session:
            return jsonify({"error": "Not authenticated"}), 401
            
        data = request.json
        item_type = data.get('type')
        content = data.get('content')
        
        if not item_type or not content:
            return jsonify({"error": "Type and content are required"}), 400
            
        result = db.save_item(session['user_id'], item_type, content)
        
        if result["success"]:
            return jsonify({"success": True, "save_id": result["save_id"]})
        else:
            return jsonify({"error": "Failed to save item"}), 500
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/get_saves', methods=['GET'])
def get_saves():
    try:
        if 'user_id' not in session:
            return jsonify({"error": "Not authenticated"}), 401
            
        item_type = request.args.get('type')
        
        result = db.get_user_saves(session['user_id'], item_type)
        
        if result["success"]:
            return jsonify({"success": True, "saves": result["saves"]})
        else:
            return jsonify({"error": "Failed to get saved items"}), 500
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/delete_save/<int:save_id>', methods=['DELETE'])
def delete_save(save_id):
    try:
        if 'user_id' not in session:
            return jsonify({"error": "Not authenticated"}), 401
            
        result = db.delete_saved_item(save_id, session['user_id'])
        
        if result["success"]:
            return jsonify({"success": True})
        else:
            return jsonify({"error": "Failed to delete saved item"}), 404
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        context = data.get('context', '')
        question = data.get('question', '')
        user_id = session.get('user_id')

        if not question:
            return jsonify({"error": "Question is required"}), 400

        add_to_chatbot_memory("user", f"Context: {context}\nQuestion: {question}")

        messages = [
            {
                "role": "system",
                "content": """
                You are a chatbot specializing in Ancient Egyptian history. 
                Answer only questions related to pharaonic figures, ancient Egyptian stories, historical sites, Egyptian identity, pyramids, and ancient Egyptian history. 
                If you don't know the answer, respond with: "I have not been provided with sufficient information on this topic."
                Always reply in English only, using a concise and easy-to-understand style.
                """
            }
        ] + CHATBOT_MEMORY

        request_params = {
            "model": "llama3-70b-8192",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 1024,
            "top_p": 1,
            "stream": True,
            "stop": None,
        }

        completion = WHERE_IM_CLIENT.chat.completions.create(**request_params)
        response_content = ""

        for chunk in completion:
            chunk_content = chunk.choices[0].delta.content or ""
            response_content += chunk_content

        add_to_chatbot_memory("assistant", response_content)
        

        if user_id:
            db.save_chat(user_id, question, response_content)
            
        return jsonify({"response": response_content})

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/chat_history', methods=['GET'])
def get_chat_history():
    try:
        if 'user_id' not in session:
            return jsonify({"error": "Not authenticated"}), 401
            
        limit = request.args.get('limit', 50, type=int)
        
        result = db.get_chat_history(session['user_id'], limit)
        
        if result["success"]:
            return jsonify({"success": True, "history": result["history"]})
        else:
            return jsonify({"error": "Failed to get chat history"}), 500
            
    except Exception as e:
        return jsonify({"error": str(e)}), 500



@app.route('/predict_where_im', methods=['POST'])
def predict_where_im():
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file part in the request"}), 400

        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400

        filepath = os.path.join(WHERE_IM_UPLOAD_FOLDER, secure_filename(file.filename))
        file.save(filepath)

        most_similar_place = find_most_similar_place_where_im(filepath)
        

        if 'user_id' in session:
            db.save_item(session['user_id'], 'where_im', {"place": most_similar_place, "image": filepath})
            
        return jsonify({"place": most_similar_place})

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    

@app.route('/who_am_i', methods=['POST'])
def who_am_i():
    try:
        if 'file' not in request.files:
            return jsonify({"error": "No file part in the request"}), 400

        file = request.files['file']
        if file.filename == '':
            return jsonify({"error": "No file selected"}), 400

        filepath = os.path.join(WHO_IM_UPLOAD_FOLDER, secure_filename(file.filename))
        file.save(filepath)

        most_similar_person = find_most_similar_person_who_am_i(filepath)
        
        if 'user_id' in session:
            db.save_item(session['user_id'], 'who_im', {"person": most_similar_person, "image": filepath})
                    
        return jsonify({"person": most_similar_person})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/translate_hieroglyphic', methods=['POST'])
def translate_hieroglyphics():
    try:
        if 'files' not in request.files:
            return jsonify({"error": "No files part in the request"}), 400

        files = request.files.getlist('files')
        if not files or len(files) > 10:
            return jsonify({"error": "You can upload between 1 and 10 images."}), 400

        predicted_classes = []
        file_paths = []
        for file in files:
            filepath = os.path.join(TRANSLATE_UPLOAD_FOLDER, secure_filename(file.filename))
            file.save(filepath)
            file_paths.append(filepath)
            predicted_class = predict_translate_class(filepath)
            predicted_classes.append(predicted_class)

        translation = generate_translate_sentence(predicted_classes)
        
        if 'user_id' in session:
            db.save_item(
                session['user_id'], 
                'translate', 
                {
                    "translation": translation,
                    "classes": predicted_classes,
                    "images": file_paths
                }
            )
            
        return jsonify({"translation": translation, "classes": predicted_classes})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


BASE_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOADS_DIR = os.path.join(BASE_DIR, 'uploads')
POST_IMAGES_DIR = os.path.join(UPLOADS_DIR, 'post_images')
USER_IMAGES_DIR = os.path.join(UPLOADS_DIR, 'user_images')


for directory in [UPLOADS_DIR, POST_IMAGES_DIR, USER_IMAGES_DIR]:
    if not os.path.exists(directory):
        os.makedirs(directory)


def init_community_tables():
    conn = sqlite3.connect('kemetpass.db')
    cursor = conn.cursor()
    

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS community_posts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''')
    

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS community_post_images (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        post_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
        FOREIGN KEY (post_id) REFERENCES community_posts (id)
    )
    ''')
    

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS community_likes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        post_id TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, post_id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (post_id) REFERENCES community_posts (id)
    )
    ''')
    

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS community_bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        post_id TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, post_id),
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (post_id) REFERENCES community_posts (id)
    )
    ''')
    

    cursor.execute('''
    CREATE TABLE IF NOT EXISTS community_comments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        post_id TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (post_id) REFERENCES community_posts (id)
    )
    ''')
    
    conn.commit()
    conn.close()
    print("تم إنشاء جداول المجتمع بنجاح")


init_community_tables()


def get_post_stats(post_id):
    conn = sqlite3.connect('kemetpass.db')
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    

    cursor.execute('SELECT COUNT(*) FROM community_likes WHERE post_id = ?', (post_id,))
    likes_count = cursor.fetchone()[0]
    

    cursor.execute('SELECT COUNT(*) FROM community_comments WHERE post_id = ?', (post_id,))
    comments_count = cursor.fetchone()[0]
    
    conn.close()
    
    return likes_count, comments_count


@app.route('/ping', methods=['GET'])
def ping():
    user_id = request.headers.get('User-ID')
    print(f"Ping received from user_id: {user_id}")
    
    response = {
        "success": True, 
        "message": "Server is running",
        "timestamp": datetime.now().isoformat()
    }
    

    if user_id:
        try:
            conn = sqlite3.connect(db.db_path)
            cursor = conn.cursor()
            cursor.execute('SELECT username FROM users WHERE id = ?', (user_id,))
            result = cursor.fetchone()
            conn.close()
            
            if result:
                response["username"] = result[0]
                response["authenticated"] = True
            else:
                response["authenticated"] = False
        except Exception as e:
            print(f"Error in ping: {str(e)}")
            response["error"] = str(e)
    
    return jsonify(response), 200


@app.route('/posts', methods=['GET'])
def get_posts():
    conn = sqlite3.connect('kemetpass.db')
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    

    cursor.execute('''
    SELECT cp.id, cp.user_id, cp.content, cp.created_at, 
           u.username, u.profile_picture as userImage,
           u.firstName, u.secondName
    FROM community_posts cp
    JOIN users u ON cp.user_id = u.id
    ORDER BY cp.created_at DESC
    ''')
    
    posts_data = cursor.fetchall()
    conn.close()
    
    posts = []
    for post in posts_data:
        post_id = post['id']
        

        conn = sqlite3.connect('kemetpass.db')
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute('SELECT image_path FROM community_post_images WHERE post_id = ?', (post_id,))
        images_data = cursor.fetchall()
        conn.close()
        

        likes_count, comments_count = get_post_stats(post_id)
        

        username = post['username'] or f"{post['firstName']} {post['secondName']}"
        

        user_image = post['userImage']
        if user_image:
            user_image = get_full_image_url(user_image)
        else:
            user_image = 'https://randomuser.me/api/portraits/lego/1.jpg'
        

        full_image_paths = []
        if images_data:
            for img in images_data:
                image_path = img['image_path']
                full_path = get_full_image_url(image_path)
                full_image_paths.append(full_path)
        

        post_dict = {
            'id': post_id,
            'userId': post['user_id'],
            'username': username,
            'userImage': user_image,
            'content': post['content'],
            'createdAt': post['created_at'],
            'likes': likes_count,
            'comments': comments_count,
            'shares': 0,
            'images': full_image_paths if full_image_paths else None
        }
        
        posts.append(post_dict)
    
    return jsonify({"success": True, "posts": posts}), 200


@app.route('/posts', methods=['POST'])
def create_post():

    user_id = request.headers.get('User-ID') or request.form.get('userId')
    content = request.form.get('content')
    
    if not user_id or not content:
        return jsonify({"success": False, "error": "Missing required fields"}), 400
    

    conn = sqlite3.connect('kemetpass.db')
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    cursor.execute('SELECT * FROM users WHERE id = ?', (user_id,))
    user = cursor.fetchone()
    
    if not user:
        conn.close()
        return jsonify({"success": False, "error": "User not found"}), 404
    

    post_id = f"post_{uuid.uuid4().hex}"
    

    cursor.execute('INSERT INTO community_posts (id, user_id, content) VALUES (?, ?, ?)',
                  (post_id, user_id, content))
    

    if 'image' in request.files:
        file = request.files['image']
        if file and file.filename:

            filename = secure_filename(f"{post_id}_{file.filename}")
            

            os.makedirs(POST_IMAGES_DIR, exist_ok=True)
            
            file_path = os.path.join(POST_IMAGES_DIR, filename)
            file.save(file_path)
            
            print(f"Saved image to: {file_path}")
            print(f"File exists after save: {os.path.exists(file_path)}")
            

            image_url = f"uploads/post_images/{filename}"
            cursor.execute('INSERT INTO community_post_images (post_id, image_path) VALUES (?, ?)',
                          (post_id, image_url))
            
            print(f"Stored image URL in database: {image_url}")
    
    conn.commit()
    conn.close()
    
    return jsonify({
        "success": True,
        "message": "Post created successfully",
        "postId": post_id
    }), 201


@app.route('/posts/<post_id>/like', methods=['POST'])
def like_post(post_id):
    user_id = request.headers.get('User-ID')
    
    if not user_id:
        return jsonify({"success": False, "error": "User ID is required"}), 400
    
    conn = sqlite3.connect('kemetpass.db')
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    

    cursor.execute('SELECT * FROM community_posts WHERE id = ?', (post_id,))
    post = cursor.fetchone()
    
    if not post:
        conn.close()
        return jsonify({"success": False, "error": "Post not found"}), 404
    
    try:

        cursor.execute('INSERT INTO community_likes (user_id, post_id) VALUES (?, ?)',
                      (user_id, post_id))
        conn.commit()
        message = "تم الإعجاب بالمنشور"
    except sqlite3.IntegrityError:

        cursor.execute('DELETE FROM community_likes WHERE user_id = ? AND post_id = ?',
                      (user_id, post_id))
        conn.commit()
        message = "تم إلغاء الإعجاب بالمنشور"
    

    cursor.execute('SELECT COUNT(*) FROM community_likes WHERE post_id = ?', (post_id,))
    likes_count = cursor.fetchone()[0]
    
    conn.close()
    
    return jsonify({
        "success": True,
        "message": message,
        "likes": likes_count
    }), 200


@app.route('/posts/<post_id>/bookmark', methods=['POST'])
def bookmark_post(post_id):
    user_id = request.headers.get('User-ID')
    data = request.get_json() or {}
    bookmark = data.get('bookmark', True)
    
    if not user_id:
        return jsonify({"success": False, "error": "User ID is required"}), 400
    
    conn = sqlite3.connect('kemetpass.db')
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    

    cursor.execute('SELECT * FROM community_posts WHERE id = ?', (post_id,))
    post = cursor.fetchone()
    
    if not post:
        conn.close()
        return jsonify({"success": False, "error": "Post not found"}), 404
    
    message = ""
    if bookmark:
        try:

            cursor.execute('INSERT INTO community_bookmarks (user_id, post_id) VALUES (?, ?)',
                          (user_id, post_id))
            conn.commit()
            message = "تمت إضافة المنشور للمفضلة"
        except sqlite3.IntegrityError:
            message = "المنشور موجود بالفعل في المفضلة"
    else:

        cursor.execute('DELETE FROM community_bookmarks WHERE user_id = ? AND post_id = ?',
                      (user_id, post_id))
        conn.commit()
        message = "تمت إزالة المنشور من المفضلة"
    
    conn.close()
    
    return jsonify({
        "success": True,
        "message": message
    }), 200


@app.route('/posts/bookmarked', methods=['GET'])
def get_bookmarked_posts():
    user_id = request.headers.get('User-ID')
    
    if not user_id:
        return jsonify({"success": False, "error": "User ID is required"}), 400
    
    conn = sqlite3.connect('kemetpass.db')
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    

    cursor.execute('''
    SELECT cp.id, cp.user_id, cp.content, cp.created_at, 
           u.username, u.profile_picture as userImage,
           u.firstName, u.secondName
    FROM community_posts cp
    JOIN users u ON cp.user_id = u.id
    JOIN community_bookmarks cb ON cp.id = cb.post_id
    WHERE cb.user_id = ?
    ORDER BY cb.created_at DESC
    ''', (user_id,))
    
    posts_data = cursor.fetchall()
    conn.close()
    
    posts = []
    for post in posts_data:
        post_id = post['id']
        

        conn = sqlite3.connect('kemetpass.db')
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute('SELECT image_path FROM community_post_images WHERE post_id = ?', (post_id,))
        images_data = cursor.fetchall()
        conn.close()
        

        likes_count, comments_count = get_post_stats(post_id)
        

        username = post['username'] or f"{post['firstName']} {post['secondName']}"
        

        post_dict = {
            'id': post_id,
            'userId': post['user_id'],
            'username': username,
            'userImage': post['userImage'] or 'https://randomuser.me/api/portraits/lego/1.jpg',
            'content': post['content'],
            'createdAt': post['created_at'],
            'likes': likes_count,
            'comments': comments_count,
            'shares': 0,
            'images': [img['image_path'] for img in images_data] if images_data else None
        }
        
        posts.append(post_dict)
    
    return jsonify({"success": True, "posts": posts}), 200


@app.route('/uploads/<path:filename>')
def uploaded_file(filename):

    print(f"Requested file: {filename}")
    print(f"UPLOADS_DIR: {UPLOADS_DIR}")
    print(f"Full path: {os.path.join(UPLOADS_DIR, filename)}")
    print(f"File exists: {os.path.exists(os.path.join(UPLOADS_DIR, filename))}")
    
    try:

        return send_from_directory(UPLOADS_DIR, filename)
    except Exception as e:
        print(f"Error serving file {filename}: {str(e)}")

        try:
            return send_from_directory('uploads', filename)
        except Exception as e2:
            print(f"Second attempt failed: {str(e2)}")
            return jsonify({"error": f"File not found: {filename}"}), 404


@app.route('/community/check_connection', methods=['GET'])
def check_community_connection():
    user_id = request.headers.get('User-ID')
    print(f"Community connection check from user: {user_id}")
    
    return jsonify({
        "success": True,
        "connected": True,
        "message": "متصل بخادم المجتمع"
    }), 200

from typing import Any, Dict, List
from pathlib import Path
import faiss
import google.generativeai as genai
import nltk
import pandas as pd
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer
PROJECT_ROOT = Path(__file__).resolve().parent
load_dotenv(PROJECT_ROOT / ".env")

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", default="API")
if not GEMINI_API_KEY:
    raise EnvironmentError("GEMINI_API_KEY missing - add it to .env")

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("gemini-1.5-flash")
data_dir = PROJECT_ROOT / "data"
df = pd.read_csv("historical_places.csv")
index = faiss.read_index("historical_places.index")
encoder = SentenceTransformer("all-mpnet-base-v2")

nltk.download("punkt", quiet=True)

SYSTEM_GUIDE = (
    "You are an award-winning local guide. Generate a day-by-day itinerary "
    "with realistic timings, logical routing, transport hints and cultural notes."
)

SCHEMA = {
    "type": "object",
    "properties": {
        "city": {"type": "string"},
        "days": {"type": "integer"},
        "plan": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "day": {"type": "integer"},
                    "date": {"type": "string"},
                    "entries": {
                        "type": "array",
                        "items": {
                            "type": "object",
                            "properties": {
                                "time": {"type": "string"},
                                "place_name": {"type": "string"},
                                "activity": {"type": "string"},
                                "notes": {"type": "string"},
                            },
                            "required": ["time", "place_name", "activity"],
                        },
                    },
                },
                "required": ["day", "date", "entries"],
            },
        },
    },
    "required": ["city", "days", "plan"],
}


def search_places(query: str, k: int = 5) -> List[Dict[str, Any]]:
    emb = encoder.encode([query])
    _, idx = index.search(emb, k)
    return df.iloc[idx[0]].to_dict("records")


def build_content(user_prefs: Dict[str, Any], places: List[Dict[str, Any]]):
    msg = (
        SYSTEM_GUIDE
        + "\nTraveller preferences JSON:\n"
        + json.dumps(user_prefs, ensure_ascii=False)
        + "\nCandidate historical places JSON:\n"
        + json.dumps(places, ensure_ascii=False)
    )
    return [{"role": "user", "parts": [msg]}]
def generate_itinerary(prefs: Dict[str, Any], k: int = 6) -> Dict[str, Any]:
    places = search_places(prefs["query"], k)
    content = build_content(prefs, places)

    resp = model.generate_content(
        contents=content,
        generation_config={
            "temperature": 0.7,
            "response_mime_type": "application/json",
            "response_schema": SCHEMA,
        },
    )

    return json.loads(resp.text)


@app.route('/plan_trip', methods=['POST'])
def plan_trip():
    try:
        data = request.json

        query = data.get('query')
        start = data.get('start')
        days = data.get('days')
        budget = data.get('budget')
        if not all([query, start, days, budget]):
            return jsonify({"error": "Missing required fields"}), 400

        prefs = {
            "query": query,
            "start": start,
            "days": int(days),
            "budget": budget
        }
        itinerary = generate_itinerary(prefs)
        return jsonify({"success": True, "itinerary": itinerary})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500


@app.route('/posts/<post_id>', methods=['DELETE'])
def delete_post(post_id):
    user_id = request.headers.get('User-ID')
    
    if not user_id:
        return jsonify({"success": False, "error": "User ID is required"}), 400
    
    conn = sqlite3.connect('kemetpass.db')
    cursor = conn.cursor()
    
    try:

        cursor.execute('SELECT user_id FROM community_posts WHERE id = ?', (post_id,))
        post_owner_id = cursor.fetchone()
        
        if not post_owner_id:
            conn.close()
            return jsonify({"success": False, "error": "Post not found"}), 404
        
        if post_owner_id[0] != user_id:
            conn.close()
            return jsonify({"success": False, "error": "Unauthorized: You do not own this post"}), 403
            

        cursor.execute('SELECT image_path FROM community_post_images WHERE post_id = ?', (post_id,))
        images_to_delete = cursor.fetchall()
        for img_path_tuple in images_to_delete:
            img_path = img_path_tuple[0]

            full_img_path = os.path.join(BASE_DIR, img_path)
            if os.path.exists(full_img_path):
                os.remove(full_img_path)
                print(f"Deleted image file: {full_img_path}")
        cursor.execute('DELETE FROM community_post_images WHERE post_id = ?', (post_id,))
        

        cursor.execute('DELETE FROM community_comments WHERE post_id = ?', (post_id,))
        

        cursor.execute('DELETE FROM community_likes WHERE post_id = ?', (post_id,))
        

        cursor.execute('DELETE FROM community_bookmarks WHERE post_id = ?', (post_id,))
        

        cursor.execute('DELETE FROM community_posts WHERE id = ?', (post_id,))
        conn.commit()
        
        return jsonify({"success": True, "message": "Post deleted successfully"}), 200
    except Exception as e:
        conn.rollback()
        print(f"Error deleting post: {str(e)}")
        return jsonify({"success": False, "error": f"Failed to delete post: {str(e)}"}), 500
    finally:
        conn.close()


if __name__ == '__main__':

    import werkzeug.serving
    from werkzeug.serving import WSGIRequestHandler
    

    WSGIRequestHandler.protocol_version = "HTTP/1.1"
    

    app.run(
        host='0.0.0.0', 
        port=8000,
        threaded=True,
        request_handler=WSGIRequestHandler
    )