# Use an official lightweight Python image
FROM python:3.9-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the requirements file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire project into the container
COPY . .

# Expose the port Flask will run on
EXPOSE 5000

# Define the command to run the Flask app
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app.app:app"]
