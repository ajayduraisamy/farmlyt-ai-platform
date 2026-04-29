from flask import Flask, render_template, request, redirect, url_for, session, flash, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
import requests
import tempfile
import io
import mysql.connector
from ultralytics import YOLO
from flask_cors import CORS
import json
import random
import string
import smtplib
import os
from datetime import datetime, timedelta
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
import razorpay
from PIL import Image
from dotenv import load_dotenv
import json, tempfile, os, io, requests
load_dotenv()

def get_db():
    return mysql.connector.connect(
        host=os.getenv("DB_HOST"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
        database=os.getenv("DB_NAME"),
        port=int(os.getenv("DB_PORT"))
    )


app = Flask(__name__)
CORS(app)
app.secret_key = 'Product_Development_Secret_Key'


### Leaf####
model = YOLO("tomato_leaf_model_v2.pt")
model1= YOLO("potato_leaf_model_v1.pt")
model2= YOLO("brinjal_leaf_model_v1.pt")
model3 =YOLO("chili_leaf_model_v2.pt")
model4 =YOLO("lady_finger_leaf_model_v1.pt")

#### veg #####
model5 =YOLO("brinjal_veg_model_v1.pt")
model6 =YOLO("cauliflower_veg_model_v1.pt")
model7 = YOLO("cucumber_veg_model_v1.pt")
model8 = YOLO("ridge_veg_model_v1.pt")
model9 = YOLO("bitter_veg_model_v1.pt")

## fruit ####
model10 = YOLO("custard_fruit_model_v1.pt")
model11 = YOLO("guava_fruit_model_v1.pt")
model12 = YOLO("pomegranate_fruit_model_v1.pt")
model13 = YOLO("lemon_fruit_model_v1.pt")
model14 = YOLO("tomato_fruit_model_v1.pt")

## flower ####
model15 = YOLO("jasmine_flower_model_v1.pt")
model16 = YOLO("rose_flower_model_v1.pt")
model17 = YOLO("marigold_flower_model_v1.pt")
model18 = YOLO("chrysanthemum_flower_model_v1.pt")


@app.route('/')
def index():
        return jsonify({"message": "Welcome to the Product Development API!"})


EMAIL_USER = os.getenv("EMAIL_USER")
EMAIL_PASS = os.getenv("EMAIL_PASS")


def generate_user_id():
    return "USR" + ''.join(random.choices(string.digits, k=6))

def generate_otp():
    return str(random.randint(100000, 999999))


# =========================
#  REGISTER API
# =========================
@app.route('/auth/register', methods=['POST'])
def register():
    data = request.get_json()

    name = data.get("name")
    email = data.get("email")
    phone = data.get("phone")

    if not (name and (email or phone)):
        return jsonify({"error": "Name + email/phone required"}), 400

    conn = get_db()
    cursor = conn.cursor()

    # Check existing user
    if email:
        cursor.execute("SELECT user_id, is_verified FROM users WHERE email=%s", (email,))
    else:
        cursor.execute("SELECT user_id, is_verified FROM users WHERE phone=%s", (phone,))

    existing_user = cursor.fetchone()

    # =========================
    #  IF USER EXISTS
    # =========================
    if existing_user:
        existing_user_id, is_verified = existing_user

        # Already verified → block
        if is_verified == 1:
            cursor.close()
            conn.close()
            return jsonify({"error": "User already exists"}), 400

        #  Not verified → resend OTP
        otp = generate_otp()
        expiry = datetime.now() + timedelta(minutes=5)

        # delete old OTPs
        cursor.execute("DELETE FROM otp_verification WHERE user_id=%s", (existing_user_id,))

        cursor.execute("""
            INSERT INTO otp_verification (user_id, otp, expiry)
            VALUES (%s,%s,%s)
        """, (existing_user_id, otp, expiry))

        conn.commit()
        cursor.close()
        conn.close()

        

        print("Resent OTP:", otp)

        return jsonify({
            "message": "OTP resent",
            "user_id": existing_user_id,
            "otp": otp,
            "resend": True
        })

    # =========================
    #  NEW USER
    # =========================

    # generate unique user_id
    while True:
        user_id = generate_user_id()
        cursor.execute("SELECT 1 FROM users WHERE user_id=%s", (user_id,))
        if not cursor.fetchone():
            break

    otp = generate_otp()
    expiry = datetime.now() + timedelta(minutes=5)

    # insert user
    cursor.execute("""
        INSERT INTO users (user_id, name, email, phone, coins, is_verified)
        VALUES (%s,%s,%s,%s,%s,%s)
    """, (user_id, name, email, phone, 50, 0))

    # insert OTP
    cursor.execute("""
        INSERT INTO otp_verification (user_id, otp, expiry)
        VALUES (%s,%s,%s)
    """, (user_id, otp, expiry))

    conn.commit()
    cursor.close()
    conn.close()

    # send OTP
    if email:
        send_email_otp(email, otp)

    print("New OTP:", otp)

    return jsonify({
        "message": "User created, OTP sent",
        "user_id": user_id,
        "otp": otp,

    })

@app.route('/auth/login', methods=['POST'])
def login():
    data = request.get_json()

    email = data.get("email")
    phone = data.get("phone")

    if not (email or phone):
        return jsonify({"error": "Email or phone required"}), 400

    conn = get_db()
    cursor = conn.cursor()

    #  Check user
    if email:
        cursor.execute("SELECT user_id, name, is_verified FROM users WHERE email=%s", (email,))
    else:
        cursor.execute("SELECT user_id, name, is_verified FROM users WHERE phone=%s", (phone,))

    row = cursor.fetchone()

    if not row:
        cursor.close()
        conn.close()
        return jsonify({"error": "User not found, please register"}), 404

    user_id, name, is_verified = row

    if not is_verified:
        cursor.close()
        conn.close()
        return jsonify({"error": "Please verify your account first"}), 403

    #  OTP spam prevention
    cursor.execute("""
        SELECT expiry FROM otp_verification 
        WHERE user_id=%s ORDER BY id DESC LIMIT 1
    """, (user_id,))

    last = cursor.fetchone()

    if last and datetime.now() < last[0]:
        cursor.close()
        conn.close()
        return jsonify({"error": "Wait before requesting new OTP"}), 429

    #  Generate OTP
    otp = generate_otp()
    expiry = datetime.now() + timedelta(minutes=5)

    cursor.execute("""
        INSERT INTO otp_verification (user_id, otp, expiry)
        VALUES (%s,%s,%s)
    """, (user_id, otp, expiry))

    conn.commit()
    cursor.close()
    conn.close()

  
    return jsonify({
        "message": "OTP sent for login",
        "user_id": user_id,
        "email": email,
        "name": name,
        "otp": otp,
        "login": True
    })


@app.route('/auth/verify-otp', methods=['POST'])
def verify_otp():
    data = request.get_json()

    user_id = data.get("user_id")
    otp = data.get("otp")

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT otp, expiry FROM otp_verification 
        WHERE user_id=%s ORDER BY id DESC LIMIT 1
    """, (user_id,))

    row = cursor.fetchone()

    if not row:
        return jsonify({"error": "OTP not found"}), 400

    db_otp, expiry = row

    if isinstance(expiry, str):
        expiry = datetime.strptime(expiry, "%Y-%m-%d %H:%M:%S")

    if datetime.now() > expiry:
        return jsonify({"error": "OTP expired"}), 400

    if otp != db_otp:
        return jsonify({"error": "Invalid OTP"}), 400

   
    cursor.execute("SELECT is_verified FROM users WHERE user_id=%s", (user_id,))
    user = cursor.fetchone()

    if user and user[0] == 0:
        cursor.execute("""
            UPDATE users SET is_verified=1 WHERE user_id=%s
        """, (user_id,))
        conn.commit()

    cursor.close()
    conn.close()

    return jsonify({
        "message": "OTP verified successfully",
        "user_id": user_id
    })

@app.route('/auth/update-profile', methods=['POST'])
def update_profile():
    data = request.get_json()
    name = data.get("name")
    user_id = data.get("user_id")
    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("""
        UPDATE users SET name=%s WHERE user_id=%s
    """, (name, user_id))

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({
        "message": "Profile updated successfully",
        "user_id": user_id
    })


def check_coins(user_id):
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("SELECT coins, is_verified FROM users WHERE user_id=%s", (user_id,))
    row = cursor.fetchone()

    if not row:
        return False, "User not found"

    coins, is_verified = row

    if not is_verified:
        return False, "User not verified"

    if coins < 10:
        return False, "Not enough coins"

    return True, "OK"


def deduct_coins(user_id):
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("""
        UPDATE users SET coins = coins - 10 WHERE user_id=%s
    """, (user_id,))

    conn.commit()
    cursor.close()
    conn.close()

@app.route('/user/wallet/<user_id>', methods=['GET'])
def wallet(user_id):
    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("SELECT coins FROM users WHERE user_id=%s", (user_id,))
    row = cursor.fetchone()

    cursor.close()
    conn.close()

    return jsonify({
        "coins": row[0] if row else 0
    })


client = razorpay.Client(auth=(
    os.getenv("RAZORPAY_KEY_ID"),
    os.getenv("RAZORPAY_KEY_SECRET")
))

@app.route('/create-order', methods=['POST'])
def create_order():
    data = request.get_json()

    amount = data.get("amount")  
    user_id = data.get("user_id")

    order = client.order.create({
        "amount": amount * 100, 
        "currency": "INR",
        "payment_capture": 1
    })

    return jsonify({
        "order_id": order['id'],
        "amount": amount,
        "user_id": user_id
    })


@app.route('/verify-payment', methods=['POST'])
def verify_payment():
    data = request.get_json()

    user_id = data.get("user_id")
    payment_id = data.get("payment_id")
    order_id = data.get("order_id")
    signature = data.get("signature")
    amount = data.get("amount")

    #  Validate input
    if not all([user_id, payment_id, order_id, signature, amount]):
        return jsonify({"error": "Missing required fields"}), 400

    try:
        #  Verify Razorpay signature
        client.utility.verify_payment_signature({
            'razorpay_order_id': order_id,
            'razorpay_payment_id': payment_id,
            'razorpay_signature': signature
        })

        amount = int(amount)

        if amount <= 0:
            return jsonify({"error": "Invalid amount"}), 400

        #  1₹ = 1 coin
        coins = amount

        conn = get_db()
        cursor = conn.cursor()

        #  Add coins to user
        cursor.execute("""
            UPDATE users SET coins = coins + %s WHERE user_id=%s
        """, (coins, user_id))

        #  Store payment history
        cursor.execute("""
            INSERT INTO payments 
            (user_id, order_id, payment_id, amount, coins_added, status)
            VALUES (%s,%s,%s,%s,%s,%s)
        """, (user_id, order_id, payment_id, amount, coins, "success"))

        conn.commit()
        cursor.close()
        conn.close()

        return jsonify({
            "message": "Payment successful",
            "coins_added": coins
        })

    except Exception as e:
        return jsonify({
            "error": "Payment verification failed",
            "details": str(e)
        }), 500


@app.route("/add_farming_tips", methods=["POST"])
def add_farming_tips():

    data = request.get_json()

    title = data.get("title")
    description = data.get("description")

    if not title or not description:
        return jsonify({"error": "Title and description required"}), 400

    try:
        conn = get_db()
        cursor = conn.cursor()

        query = "INSERT INTO farming_tips (title, description) VALUES (%s,%s)"
        cursor.execute(query, (title, description))

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({"message": "Tip added successfully"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route("/get_farming_tips")
def get_farming_tips():

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM farming_tips")
    rows = cursor.fetchall()

    cursor.close()
    conn.close()

    tips = []
    for row in rows:
        tips.append({
            "id": row[0], 
            "title": row[1],
            "description": row[2]
        })

    return jsonify(tips)


@app.route('/update_farming_tips/<int:id>', methods=['PUT'])
def update_farming_tips(id):

    data = request.get_json()

    title = data.get('title')
    description = data.get('description')

    try:
        conn = get_db()
        cursor = conn.cursor()
      
        query = "UPDATE farming_tips SET title=%s, description=%s WHERE id=%s"
        cursor.execute(query, (title, description, id))

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({"message": "Tip updated"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/delete_farming_tips/<int:id>', methods=['DELETE'])
def delete_farming_tips(id):

    try:
        conn = get_db()
        cursor = conn.cursor()

        query = "DELETE FROM farming_tips WHERE id=%s"
        cursor.execute(query, (id,))

        conn.commit()

        cursor.close()
        conn.close()

        return jsonify({"message": "Tip deleted"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/add_agri_title', methods=['POST'])
def add_agri_title():
    
    title = request.form.get('title')
    image = request.files.get('image')   

    if not title or not image:
        return jsonify({"status": "error", "message": "Title and image required"}), 400

    files = {
        "image": (image.filename, image.stream, image.mimetype)
    }

    try:
        upload = requests.post(
            "https://example.com/Api/product_development/upload.php",
            files=files,
            timeout=20
        )
        data = upload.json()
    except Exception as e:
        return jsonify({"error": "Upload failed", "details": str(e)}), 500

    if data.get("status") != "success":
        return jsonify({"error": "Image upload failed"}), 500

    image_url = data["url"]

    conn = get_db()
    cursor = conn.cursor()

    query = "INSERT INTO agri (title, image_url) VALUES (%s, %s)"
    cursor.execute(query, (title, image_url))
    conn.commit()

    cursor.close()
    conn.close()

    return jsonify({
        "status": "success",
        "message": "Title added successfully",
        "image_url": image_url
    })


@app.route('/get_agri_titles', methods=['GET'])
def get_agri_titles():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)  
    cursor.execute("SELECT * FROM agri")
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(rows)

@app.route('/update_agri_title', methods=['POST'])
def update_agri_title():
    id = request.form.get('id')
    title = request.form.get('title')
    image = request.files.get('image')   

    if not id or not title:
        return jsonify({"status": "error", "message": "ID and Title required"}), 400

    conn = get_db()
    cursor = conn.cursor()

    image_url = None

    if image and image.filename:
        files = {
            "image": (image.filename, image.stream, image.mimetype)
        }

        try:
            upload = requests.post(
                "https://example.com/Api/product_development/upload.php",
                files=files,
                timeout=20
            )
            data = upload.json()
        except Exception as e:
            return jsonify({"error": "Upload failed", "details": str(e)}), 500

        if data.get("status") != "success":
            return jsonify({"error": "Image upload failed"}), 500

        image_url = data["url"]


    if image_url:
        cursor.execute("""
            UPDATE agri 
            SET title=%s, image_url=%s 
            WHERE id=%s
        """, (title, image_url, id))
    else:
        cursor.execute("""
            UPDATE agri 
            SET title=%s 
            WHERE id=%s
        """, (title, id))

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({
        "status": "success",
        "message": "Title updated successfully"
    })

@app.route('/delete_agri_title', methods=['POST'])
def delete_agri_title():
    id = request.form.get('id')

    if not id:
        return jsonify({"status": "error", "message": "ID required"}), 400

    conn = get_db()
    cursor = conn.cursor()

    query = "DELETE FROM agri WHERE id = %s"
    cursor.execute(query, (id,))
    conn.commit()

    cursor.close()
    conn.close()

    return jsonify({"status": "success", "message": "Title deleted successfully"})

@app.route('/add_crop', methods=['POST'])
def add_crop():
    title = request.form.get("title")
    agri_id = request.form.get("agri_id")  
    image = request.files.get("image")

    if not title or not agri_id or not image:
        return jsonify({"error": "title, agri_id and image required"}), 400

    files = {"image": (image.filename, image.stream, image.mimetype)}

    try:
        upload = requests.post(
            "https://example.com/Api/product_development/upload.php",
            files=files, timeout=20
        )
        data = upload.json()
    except Exception as e:
        return jsonify({"error": "Upload failed", "details": str(e)}), 500

    if data.get("status") != "success" or "url" not in data:
        return jsonify({"error": "Image upload failed", "api_response": data}), 500

    image_url = data["url"]

    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute(
            "INSERT INTO crop (title, agri_id, image_url) VALUES (%s, %s, %s)",
            (title, agri_id, image_url)  
        )
        conn.commit()
        cursor.close()
        conn.close()
    except Exception as e:
        return jsonify({"error": "Database insert failed", "details": str(e)}), 500

    return jsonify({"message": "Crop added successfully", "image_url": image_url})


@app.route('/get_crops', methods=['GET'])
def get_crops():
    try:
        conn = get_db()
        cursor = conn.cursor()

        # JOIN to get agri title too
        cursor.execute("""
            SELECT c.id, c.title, c.agri_id, a.title as agri_title, c.image_url, c.created_date 
            FROM crop c
            LEFT JOIN agri a ON c.agri_id = a.id
        """)
        rows = cursor.fetchall()

        crops = []
        for row in rows:
            crops.append({
                "id": row[0],
                "title": row[1],
                "agri_id": row[2],
                "agri_title": row[3], 
                "image_url": row[4],
                "created_date": str(row[5])
            })

        cursor.close()
        conn.close()
        return jsonify(crops)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/update_crop/<int:id>', methods=['PUT'])
def update_crop(id):
    title   = request.form.get("title")
    agri_id = request.form.get("agri_id")
    image   = request.files.get("image") 

    if not title or not agri_id:
        return jsonify({"error": "title and agri_id are required"}), 400

    image_url = None

    # Only upload if a new image was provided
    if image and image.filename:
        files = {'image': (image.filename, image.stream, image.mimetype)}
        try:
            upload = requests.post(
                "https://example.com/Api/product_development/upload.php",
                files=files, timeout=20
            )
            data = upload.json()
        except Exception as e:
            return jsonify({"error": "Upload failed", "details": str(e)}), 500

        if data.get("status") != "success" or "url" not in data:
            return jsonify({"error": "Image upload failed", "api_response": data}), 500

        image_url = data["url"]

    try:
        conn = get_db()
        cursor = conn.cursor()

        if image_url:
            # Update with new image
            cursor.execute("""
                UPDATE crop SET title=%s, agri_id=%s, image_url=%s WHERE id=%s
            """, (title, agri_id, image_url, id))
        else:
            # Update without changing image
            cursor.execute("""
                UPDATE crop SET title=%s, agri_id=%s WHERE id=%s
            """, (title, agri_id, id))

        conn.commit()
        cursor.close()
        conn.close()

    except Exception as e:
        return jsonify({"error": "Database update failed", "details": str(e)}), 500

    return jsonify({"message": "Crop updated successfully"})

@app.route('/delete_crop/<int:id>', methods=['DELETE'])
def delete_crop(id):
    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM crop WHERE id=%s", (id,))
        conn.commit()
        cursor.close()
        conn.close()
        return jsonify({"message": "Crop deleted"})
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.route('/add_crop_sub', methods=['POST'])
def add_crop_sub():

    crop_id = request.form.get("crop_id")
    title = request.form.get("title")
    image = request.files.get("image")

    if not crop_id or not title or not image:
        return jsonify({"error": "crop_id, title and image required"}), 400

    files = {
        "image": (image.filename, image.stream, image.mimetype)
    }

    try:
        upload = requests.post(
            "https://example.com/Api/product_development/upload.php",
            files=files,
            timeout=20
        )

        data = upload.json()

    except Exception as e:
        return jsonify({
            "error": "Upload request failed",
            "details": str(e)
        }), 500

    if data.get("status") != "success" or "url" not in data:
        return jsonify({
            "error": "Image upload failed",
            "api_response": data
        }), 500

    image_url = data["url"]

    try:
        conn = get_db()
        cursor = conn.cursor()

        cursor.execute(
            "INSERT INTO crop_sub (crop_id, title, image_url) VALUES (%s,%s,%s)",
            (crop_id, title, image_url)
        )

        conn.commit()
        cursor.close()
        conn.close()

    except Exception as e:
        return jsonify({
            "error": "Database insert failed",
            "details": str(e)
        }), 500

    return jsonify({
        "message": "Sub Crop added successfully",
        "image_url": image_url
    })


@app.route('/get_crop_sub', methods=['GET'])
def get_crop_sub():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT cs.*, c.title as crop_name
        FROM crop_sub cs
        JOIN crop c ON cs.crop_id = c.id
        ORDER BY cs.id DESC
    """)

    data = cursor.fetchall()

    cursor.close()
    conn.close()

    return jsonify(data)

@app.route('/update_crop_sub/<int:id>', methods=['POST'])
def update_crop_sub(id):
    title = request.form.get("title")
    crop_id = request.form.get("crop_id")
    image = request.files.get("image")

    conn = get_db()
    cursor = conn.cursor()

    # Upload new image if exists
    if image:
        files = {
            "image": (image.filename, image.stream, image.mimetype)
        }

        upload = requests.post(
            "https://example.com/Api/product_development/upload.php",
            files=files
        )

        data = upload.json()

        if data.get("status") != "success":
            return jsonify({"error": "Image upload failed"}), 500

        image_url = data["url"]

        cursor.execute(
            "UPDATE crop_sub SET crop_id=%s, title=%s, image_url=%s WHERE id=%s",
            (crop_id, title, image_url, id)
        )
    else:
        cursor.execute(
            "UPDATE crop_sub SET crop_id=%s, title=%s WHERE id=%s",
            (crop_id, title, id)
        )

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"message": "Updated successfully"})

@app.route('/delete_crop_sub/<int:id>', methods=['DELETE'])
def delete_crop_sub(id):

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("DELETE FROM crop_sub WHERE id=%s", (id,))
    conn.commit()

    cursor.close()
    conn.close()

    return jsonify({"message": "Deleted successfully"})

@app.route('/add_product', methods=['POST'])
def add_product():
    crop_sub_id = request.form.get("crop_sub_id")
    disease_name = request.form.get("disease_name")

    fertilizers = request.form.get("fertilizers")
    pesticides = request.form.get("pesticides")
    care_points = request.form.get("care_points")

    #  PRODUCT 1
    p1_name = request.form.get("product1_name")
    p1_url = request.form.get("product1_url")
    p1_image = request.files.get("product1_image")

    #  PRODUCT 2
    p2_name = request.form.get("product2_name")
    p2_url = request.form.get("product2_url")
    p2_image = request.files.get("product2_image")

    #  PRODUCT 3
    p3_name = request.form.get("product3_name")
    p3_url = request.form.get("product3_url")
    p3_image = request.files.get("product3_image")

    #  PRODUCT 4
    p4_name = request.form.get("product4_name")
    p4_url = request.form.get("product4_url")
    p4_image = request.files.get("product4_image")

    if not all([crop_sub_id, disease_name, p1_name, p1_url]):
        return jsonify({"error": "Missing required fields"}), 400

    def upload_image(img):
        if not img:
            return None

        files = {
            "image": (img.filename, img.stream, img.mimetype)
        }

        res = requests.post(
            "https://example.com/Api/product_development/upload.php",
            files=files
        )

        data = res.json()
        return data.get("url") if data.get("status") == "success" else None

    # Upload all images
    img1 = upload_image(p1_image)
    img2 = upload_image(p2_image)
    img3 = upload_image(p3_image)
    img4 = upload_image(p4_image)

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO crop_products (
            crop_sub_id, disease_name,
            product1_name, product1_url, product1_image,
            product2_name, product2_url, product2_image,
            product3_name, product3_url, product3_image,
            product4_name, product4_url, product4_image,
            fertilizers, pesticides, care_points
        ) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
    """, (
        crop_sub_id, disease_name,
        p1_name, p1_url, img1,
        p2_name, p2_url, img2,
        p3_name, p3_url, img3,
        p4_name, p4_url, img4,
        fertilizers, pesticides, care_points
    ))

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"message": "4 products added successfully"})


@app.route('/get_crop_with_products', methods=['GET'])
def get_crop_with_products():
    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    cursor.execute("""
        SELECT cs.id, cs.title, cs.image_url, c.title as crop_name
        FROM crop_sub cs
        JOIN crop c ON cs.crop_id = c.id
    """)

    crops = cursor.fetchall()

    # attach products
    for crop in crops:
        cursor.execute("""
            SELECT *
            FROM crop_products 
            WHERE crop_sub_id=%s
        """, (crop['id'],))

        rows = cursor.fetchall()

        product_list = []

        for row in rows:
            # convert 4 columns → array
            product_list.append({
                "disease_name": row["disease_name"],
                "products": [
                    {
                        "product_name": row["product1_name"],
                        "product_url": row["product1_url"],
                        "product_image": row["product1_image"]
                    },
                    {
                        "product_name": row["product2_name"],
                        "product_url": row["product2_url"],
                        "product_image": row["product2_image"]
                    },
                    {
                        "product_name": row["product3_name"],
                        "product_url": row["product3_url"],
                        "product_image": row["product3_image"]
                    },
                    {
                        "product_name": row["product4_name"],
                        "product_url": row["product4_url"],
                        "product_image": row["product4_image"]
                    }
                ],
                "fertilizers": row["fertilizers"],
                "pesticides": row["pesticides"],
                "care_points": row["care_points"]
            })

        crop['products'] = product_list

    cursor.close()
    conn.close()

    return jsonify(crops)

@app.route('/update_product/<int:id>', methods=['POST'])
def update_product(id):
    crop_sub_id = request.form.get("crop_sub_id")
    disease_name = request.form.get("disease_name")

    fertilizers = request.form.get("fertilizers")
    pesticides = request.form.get("pesticides")
    care_points = request.form.get("care_points")

    # Products
    p1_name = request.form.get("product1_name")
    p1_url = request.form.get("product1_url")
    p1_image = request.files.get("product1_image")

    p2_name = request.form.get("product2_name")
    p2_url = request.form.get("product2_url")
    p2_image = request.files.get("product2_image")

    p3_name = request.form.get("product3_name")
    p3_url = request.form.get("product3_url")
    p3_image = request.files.get("product3_image")

    p4_name = request.form.get("product4_name")
    p4_url = request.form.get("product4_url")
    p4_image = request.files.get("product4_image")

    conn = get_db()
    cursor = conn.cursor(dictionary=True)

    # get existing data (so we don't lose old images)
    cursor.execute("SELECT * FROM crop_products WHERE id=%s", (id,))
    existing = cursor.fetchone()

    if not existing:
        return jsonify({"error": "Product not found"}), 404

    def upload_image(img):
        if not img:
            return None

        files = {"image": (img.filename, img.stream, img.mimetype)}

        res = requests.post(
            "https://example.com/Api/product_development/upload.php",
            files=files
        )

        data = res.json()
        return data.get("url") if data.get("status") == "success" else None

    # upload new images or keep old
    img1 = upload_image(p1_image) or existing["product1_image"]
    img2 = upload_image(p2_image) or existing["product2_image"]
    img3 = upload_image(p3_image) or existing["product3_image"]
    img4 = upload_image(p4_image) or existing["product4_image"]

    cursor.execute("""
        UPDATE crop_products SET
            crop_sub_id=%s,
            disease_name=%s,

            product1_name=%s,
            product1_url=%s,
            product1_image=%s,

            product2_name=%s,
            product2_url=%s,
            product2_image=%s,

            product3_name=%s,
            product3_url=%s,
            product3_image=%s,

            product4_name=%s,
            product4_url=%s,
            product4_image=%s,

            fertilizers=%s,
            pesticides=%s,
            care_points=%s

        WHERE id=%s
    """, (
        crop_sub_id,
        disease_name,

        p1_name, p1_url, img1,
        p2_name, p2_url, img2,
        p3_name, p3_url, img3,
        p4_name, p4_url, img4,

        fertilizers,
        pesticides,
        care_points,

        id
    ))

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"message": "Product updated successfully"})


@app.route('/add_tip', methods=['POST'])
def add_tip():
    data = request.get_json()

    crop_sub_id = data.get("crop_sub_id")
    tip_title = data.get("tip_title")
    tip_description = data.get("tip_description")

    if not crop_sub_id or not tip_title or not tip_description:
        return jsonify({"error": "All fields required"}), 400

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("""
        INSERT INTO sub_crop_tips (crop_sub_id, tip_title, tip_description)
        VALUES (%s,%s,%s)
    """, (crop_sub_id, tip_title, tip_description))

    conn.commit()
    cursor.close()
    conn.close()

    return jsonify({"message": "Tip added successfully"})

@app.route('/get_tips', methods=['GET'])
def get_tips():
    conn = get_db()
    cursor = conn.cursor(dictionary=True) 

    cursor.execute("""
        SELECT sct.id, sct.tip_title, sct.tip_description, cs.title as crop_sub_name
        FROM sub_crop_tips sct
        JOIN crop_sub cs ON sct.crop_sub_id = cs.id
    """)

    tips = cursor.fetchall()

    cursor.close()
    conn.close()

    return jsonify(tips)

################################################### helpers    ###################################
def get_crop_sub_id(crop_name):
    conn = get_db()
    cursor = conn.cursor()

    crop_name = crop_name.lower().replace("_", " ")

    cursor.execute("""
        SELECT id FROM crop_sub 
        WHERE LOWER(title) = %s
        LIMIT 1
    """, (crop_name,))

    row = cursor.fetchone()

    cursor.close()
    conn.close()

    return row[0] if row else None

def get_disease_info(crop_sub_id, disease_name):
    try:
        conn = get_db()
        cursor = conn.cursor(dictionary=True)

        disease_name = disease_name.strip().lower()

        cursor.execute("""
            SELECT * FROM crop_products
            WHERE crop_sub_id = %s 
            AND LOWER(disease_name) = %s
            LIMIT 1
        """, (crop_sub_id, disease_name))

        row = cursor.fetchone()

        if not row:
            print(" NO MATCH FOUND")
            return None

        print(" MATCH FOUND:", row["disease_name"])

        fertilizers = row['fertilizers'].split(',') if row['fertilizers'] else []
        pesticides = row['pesticides'].split(',') if row['pesticides'] else []
        care_points = row['care_points'].split(',') if row['care_points'] else []

        products = []

        for i in range(1, 5):
            if row.get(f"product{i}_name"):
                products.append({
                    "product_name": row[f"product{i}_name"],
                    "product_url": row[f"product{i}_url"],
                    "product_image": row[f"product{i}_image"]
                })

        return {
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }

    except Exception as e:
        print("DB Error:", e)
        return None

################################  ## LEAFS Detection ##

@app.route('/leafs/tomato', methods=['POST'])
def tomato():

   
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "leaf"
    crop = "tomato"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Tomato Leaf Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                crop,
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products   
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


@app.route('/leafs/potato', methods=['POST'])
def potato():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "leaf"
    crop = "potato"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL (OPTIONAL - CAN MOVE TO BG)
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model1(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model1.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Potato Leaf Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                crop,
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


@app.route('/leafs/brinjal', methods=['POST'])
def brinjal():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "leaf"
    crop = "brinjal"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model2(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model2.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Brinjal Leaf Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                crop,
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)
   

@app.route('/leafs/chili', methods=['POST'])
def chili():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "leaf"
    crop = "chilli"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model3(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model3.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Chili Leaf Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                crop,
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)
    
@app.route('/leafs/ladyfinger', methods=['POST'])
def ladyfinger():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "leaf"
    crop = "lady_finger"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model4(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model4.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Lady Finger Leaf Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({ "error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                crop,
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

############################################## Vejitables ##############################################

@app.route('/vegtables/brinjal', methods=['POST'])
def vegtables_brinjal():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "vegetable"
    crop = "brinjal_veg"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model5(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model5.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Brinjal Vegitable Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "brinjal_veg",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


@app.route('/vegtables/cauliflower', methods=['POST'])
def vegtables_cauliflower():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "vegetable"
    crop = "cauliflower"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model6(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model6.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Califlower Vegitable Detected Upload Proper Image"
        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "cauliflower",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

@app.route('/vegtables/cucumber', methods=['POST'])
def vegtables_cucumber():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "vegetable"
    crop = "cucumber"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model7(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model7.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Cucumber Vegitable Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "cucumber",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

@app.route('/vegtables/ridge', methods=['POST'])
def vegtables_ridge():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "vegetable"
    crop = "Ridge Gourd"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model8(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model8.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Ridge Vegitable Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "ridge",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

@app.route('/vegtables/bitter_gourd', methods=['POST'])
def vegtables_bitter_gourd():

    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "vegetable"
    crop = "bitter_gourd"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model9(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model9.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Bitter Gourd Vegitable Detected Upload Proper Image"
        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "bitter_gourd",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

##############################################     fruits #################################3

@app.route('/fruits/custard_apple', methods=['POST'])
def fruits_custard_apple():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "fruit"
    crop = "custard_apple"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model10(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model10.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Custard Apple Fruit Detected Upload Proper Image"
        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "custard_apple",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


@app.route('/fruits/guava', methods=['POST'])
def fruits_guava():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "fruit"
    crop = "guava"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model11(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model11.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Guava Fruit Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "guava",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


@app.route('/fruits/pomegranate', methods=['POST'])
def fruits_pomegranate():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "fruit"
    crop = "pomegranate"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model12(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model12.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Pomegranate Fruit Detected Upload Proper Image"

        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "pomegranate",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

@app.route('/fruits/lemon', methods=['POST'])
def fruits_lemon():
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "fruit"
    crop = "lemon_fruit"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  PREDICTION (USE YOUR MODEL)
        results = model13(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model13.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Lemon Fruit Detected Upload Proper Image"

        #  DB DATA
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400

        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  PREDICTED IMAGE UPLOAD
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                crop,
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

    

@app.route('/fruits/tomato', methods=['POST'])
def fruits_tomato():
    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "fruit"
    crop = "tomato_fruit"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model14(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model14.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Tomato Fruit Detected Upload Proper Image"
        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "tomato_fruit",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

#################################################################### Flowers ##############################3

@app.route('/flowers/jasmine', methods=['POST'])
def flowers_jasmine():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "flower"
    crop = "jasmine"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model15(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model15.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Jasmine Flower Detected Upload Proper Image"
        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "jasmine",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


@app.route('/flowers/rose', methods=['POST'])
def flowers_rose():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "flower"
    crop = "rose"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model16(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model16.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Rose Flower Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "rose",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)


@app.route('/flowers/marigold', methods=['POST'])
def flowers_marigold():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "flower"
    crop = "marigold"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model17(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model17.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Marigold Flower Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "marigold",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

@app.route('/flowers/chrysanthemums', methods=['POST'])
def flowers_chrysanthemums():

    #  STEP 1: USER CHECK
    user_id = request.form.get("user_id")

    if not user_id:
        return jsonify({"error": "user_id required"}), 400

    success, msg = check_coins(user_id)
    if not success:
        return jsonify({"error": msg}), 400

    category = "flower"
    crop = "chrysanthemum"

    image = request.files.get("image")
    if not image:
        return jsonify({"error": "Image required"}), 400

    temp_path = None

    try:
        #  STEP 2: SAVE TEMP IMAGE
        temp = tempfile.NamedTemporaryFile(delete=False, suffix=".jpg")
        temp_path = temp.name
        temp.close()
        image.save(temp_path)

        #  STEP 3: UPLOAD ORIGINAL
        original_url = None
        try:
            with open(temp_path, "rb") as f:
                res = requests.post(
                    "https://example.com/Api/product_development/file.php",
                    files={"image": (image.filename, f, "image/jpeg")},
                    data={"category": category, "crop": crop, "type": "original"},
                    timeout=20
                )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    original_url = data.get("url")

        except Exception as e:
            print("Original upload error:", e)

        #  STEP 4: PREDICTION
        results = model18(temp_path)
        r = results[0]

        final_disease = None
        max_conf = 0
        text_output = ""

        if hasattr(r, "boxes") and r.boxes is not None:
            for box in r.boxes:
                cls = int(box.cls[0])
                conf = float(box.conf[0])
                name = model18.names[cls]

                text_output += f"{name} ({conf:.2f})\n"

                if conf > max_conf:
                    max_conf = conf
                    final_disease = name

        result = text_output if text_output else "No Chrysanthemum Flower Detected Upload Proper Image"

        
        crop_sub_id = get_crop_sub_id(crop)
        if not crop_sub_id:
            return jsonify({"error": f"Crop '{crop}' not found in DB"}), 400
        db_data = get_disease_info(crop_sub_id, final_disease)

        if db_data:
            fertilizers = db_data.get("fertilizers", [])
            pesticides = db_data.get("pesticides", [])
            care_points = db_data.get("care_points", [])
            products = db_data.get("products", [])
        else:
            fertilizers = []
            pesticides = []
            care_points = []
            products = []

        #  STEP 6: CREATE + UPLOAD PREDICTED
        predicted_url = None
        try:
            plotted = r.plot()
            pil_img = Image.fromarray(plotted[..., ::-1])

            img_bytes = io.BytesIO()
            pil_img.save(img_bytes, format="JPEG")
            img_bytes.seek(0)

            res = requests.post(
                "https://example.com/Api/product_development/file.php",
                files={"image": ("prediction.jpg", img_bytes, "image/jpeg")},
                data={"category": category, "crop": crop, "type": "predicted"},
                timeout=20
            )

            if res.status_code == 200:
                data = res.json()
                if data.get("status") == "success":
                    predicted_url = data.get("url")

        except Exception as e:
            print("Predicted upload error:", e)

        #  STEP 7: SAVE DB
        try:
            conn = get_db()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO leaf_predictions 
                (crop, original_image_url, predicted_image_url, prediction_result, disease_name, fertilizers, pesticides, care_points)
                VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
            """, (
                "chrysanthemum",
                original_url,
                predicted_url,
                result,
                final_disease,
                json.dumps(fertilizers),
                json.dumps(pesticides),
                json.dumps(care_points)
            ))

            conn.commit()
            cursor.close()
            conn.close()

        except Exception as e:
            print("DB error:", e)

        #  STEP 8: DEDUCT COINS
        try:
            deduct_coins(user_id)
        except Exception as e:
            print("Coin error:", e)

        #  FINAL RESPONSE 
        return jsonify({
            "message": "Prediction completed",
            "original_image": original_url,
            "predicted_image": predicted_url,
            "image_url": predicted_url,
            "prediction": result,
            "disease": final_disease,
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points,
            "products": products
        }), 200

    except Exception as e:
        return jsonify({
            "error": "Critical failure",
            "details": str(e)
        }), 500

    finally:
        if temp_path and os.path.exists(temp_path):
            os.remove(temp_path)

@app.route('/get_leaf_predictions', methods=['GET'])
def get_leaf_predictions():
    import json
    from datetime import datetime

    conn = get_db()
    cursor = conn.cursor()

    cursor.execute("""
        SELECT id, crop, original_image_url, predicted_image_url, prediction_result, created_at,
               disease_name, fertilizers, pesticides, care_points
        FROM leaf_predictions
        ORDER BY id DESC
    """)

    rows = cursor.fetchall()
    data = []

    for row in rows:

        created_at = row[5]

        if isinstance(created_at, datetime):
            created_at = created_at.strftime("%Y-%m-%d %H:%M:%S")
        else:
            created_at = str(created_at) if created_at else None

        try:
            fertilizers = json.loads(row[7]) if row[7] else []
        except:
            fertilizers = []

        try:
            pesticides = json.loads(row[8]) if row[8] else []
        except:
            pesticides = []

        try:
            care_points = json.loads(row[9]) if row[9] else []
        except:
            care_points = []

        data.append({
            "id": row[0],
            "crop": row[1],

            #  FIX HERE
            "original_image": row[2],
            "predicted_image": row[3],

            "prediction": row[4],
            "created_at": created_at,
            "disease": row[6],
            "fertilizers": fertilizers,
            "pesticides": pesticides,
            "care_points": care_points
        })

    cursor.close()
    conn.close()

    return jsonify(data)
########################
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=7860)