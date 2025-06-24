import sqlite3
import os
import json
from werkzeug.security import generate_password_hash, check_password_hash

class DatabaseHandler:
    def __init__(self, db_path='kemetpass.db'):
        """Initialize database connection"""
        self.db_path = db_path
        self._initialize_db()
    
    def _initialize_db(self):
        """Create database tables if they don't exist"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Users table
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            username TEXT,
            profile_picture TEXT,
            firstName TEXT,
            secondName TEXT,
            phone TEXT,
            country TEXT,
            language TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
        ''')
        
        # User saved items
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_saves (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            type TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
        ''')
        
        # Chat history
        cursor.execute('''
        CREATE TABLE IF NOT EXISTS chat_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            message TEXT NOT NULL,
            response TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id)
        )
        ''')
        
        conn.commit()
        conn.close()
    
    # User Authentication Methods
    def register_user(self, email, password, username=None, profile_picture=None, firstName=None, secondName=None):
        """Register a new user"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            password_hash = generate_password_hash(password)
            
            # Print registration data for debugging
            print(f"Python: Registering user with username: {username}, firstName: {firstName}, secondName: {secondName}")
            
            # تسجيل قيم الإدخال للأغراض التشخيصية
            print(f"Python: Inserting user: email={email}, username={username}, firstName={firstName}, secondName={secondName}")
            
            cursor.execute(
                'INSERT INTO users (email, password_hash, username, profile_picture, firstName, secondName) VALUES (?, ?, ?, ?, ?, ?)',
                (email, password_hash, username, profile_picture, firstName, secondName)
            )
            
            user_id = cursor.lastrowid
            
            # التحقق من البيانات المدخلة
            cursor.execute('SELECT id, email, username, firstName, secondName FROM users WHERE id = ?', (user_id,))
            inserted_user = cursor.fetchone()
            print(f"Python: Inserted user record: {inserted_user}")
            
            conn.commit()
            conn.close()
            return {"success": True, "user_id": user_id}
        except sqlite3.IntegrityError:
            return {"success": False, "error": "Email already exists"}
        except Exception as e:
            print(f"Python Error in register_user: {str(e)}")
            return {"success": False, "error": str(e)}
    
    def login_user(self, email, password):
        """Authenticate a user"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute('SELECT id, email, password_hash, username, profile_picture, firstName, secondName, phone, country, language FROM users WHERE email = ?', (email,))
        user = cursor.fetchone()
        print(f"Python: Login attempt for {email}, found user: {user}")
        conn.close()
        
        if user and check_password_hash(user[2], password):
            response = {
                "success": True,
                "user": {
                    "id": user[0],
                    "email": user[1],
                    "username": user[3],
                    "profile_picture": user[4],
                    "firstName": user[5] or "",
                    "secondName": user[6] or "",
                    "phone": user[7] or "",
                    "country": user[8] or "Egypt",
                    "language": user[9] or "English"
                }
            }
            print(f"Python: Login successful, returning user data: {response['user']}")
            return response
        print(f"Python: Login failed for {email}")
        return {"success": False, "error": "Invalid email or password"}
    
    def update_user_profile(self, user_id, firstName=None, secondName=None, username=None, email=None, phone=None, country=None, language=None, profile_picture=None):
        """Update user profile information"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        update_fields = []
        params = []
        
        # Add all profile fields
        if firstName is not None:
            update_fields.append("firstName = ?")
            params.append(firstName)
            
        if secondName is not None:
            update_fields.append("secondName = ?")
            params.append(secondName)
        
        if username is not None:
            update_fields.append("username = ?")
            params.append(username)
            
        if email is not None:
            update_fields.append("email = ?")
            params.append(email)
            
        if phone is not None:
            update_fields.append("phone = ?")
            params.append(phone)
            
        if country is not None:
            update_fields.append("country = ?")
            params.append(country)
            
        if language is not None:
            update_fields.append("language = ?")
            params.append(language)
        
        if profile_picture is not None:
            update_fields.append("profile_picture = ?")
            params.append(profile_picture)
        
        if not update_fields:
            return {"success": False, "error": "No fields to update"}
        
        params.append(user_id)
        query = f"UPDATE users SET {', '.join(update_fields)} WHERE id = ?"
        
        cursor.execute(query, params)
        conn.commit()
        conn.close()
        
        return {"success": True}
    
    # User Saves Methods
    def save_item(self, user_id, item_type, content):
        """Save an item for a user"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        content_json = json.dumps(content)
        cursor.execute(
            'INSERT INTO user_saves (user_id, type, content) VALUES (?, ?, ?)',
            (user_id, item_type, content_json)
        )
        
        save_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        return {"success": True, "save_id": save_id}
    
    def get_user_saves(self, user_id, item_type=None):
        """Get all saved items for a user"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        if item_type:
            cursor.execute(
                'SELECT id, type, content, created_at FROM user_saves WHERE user_id = ? AND type = ? ORDER BY created_at DESC',
                (user_id, item_type)
            )
        else:
            cursor.execute(
                'SELECT id, type, content, created_at FROM user_saves WHERE user_id = ? ORDER BY created_at DESC',
                (user_id,)
            )
        
        rows = cursor.fetchall()
        conn.close()
        
        saves = []
        for row in rows:
            content = json.loads(row[2])
            saves.append({
                "id": row[0],
                "type": row[1],
                "content": content,
                "created_at": row[3]
            })
        
        return {"success": True, "saves": saves}
    
    def delete_saved_item(self, save_id, user_id):
        """Delete a saved item"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(
            'DELETE FROM user_saves WHERE id = ? AND user_id = ?',
            (save_id, user_id)
        )
        
        success = cursor.rowcount > 0
        conn.commit()
        conn.close()
        
        return {"success": success}
    
    # Chat History Methods
    def save_chat(self, user_id, message, response):
        """Save a chat message and response"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(
            'INSERT INTO chat_history (user_id, message, response) VALUES (?, ?, ?)',
            (user_id, message, response)
        )
        
        chat_id = cursor.lastrowid
        conn.commit()
        conn.close()
        
        return {"success": True, "chat_id": chat_id}
    
    def get_chat_history(self, user_id, limit=50):
        """Get chat history for a user"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute(
            'SELECT id, message, response, created_at FROM chat_history WHERE user_id = ? ORDER BY created_at DESC LIMIT ?',
            (user_id, limit)
        )
        
        rows = cursor.fetchall()
        conn.close()
        
        history = []
        for row in rows:
            history.append({
                "id": row[0],
                "message": row[1],
                "response": row[2],
                "created_at": row[3]
            })
        
        return {"success": True, "history": history} 