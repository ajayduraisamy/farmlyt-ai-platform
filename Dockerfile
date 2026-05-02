FROM python:3.10

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .


ENV DB_HOST= Your DB Host
ENV DB_USER= Your DB User
ENV DB_PASSWORD= Your DB Password
ENV DB_NAME= Your DB Name
ENV DB_PORT= Your DB Port

ENV EMAIL_USER= Your Email User
ENV EMAIL_PASS= Your Email Password

ENV RAZORPAY_KEY_ID=rzp_test_1DP5mmOlF5G5ag
ENV RAZORPAY_KEY_SECRET=rzp_test_1DP5mmOlF5G5ag
# Expose port
EXPOSE 7860

# Run app
CMD ["python", "app.py"]