# Step 1: Use a tiny Linux version with Python already installed
FROM python:3.9-slim

# Step 2: Set the folder inside the container where we will work
WORKDIR /app

# Step 3: Copy your HTML file into the container
COPY index.html .

# Step 4: Command to start a simple web server on port 8080
CMD ["python", "-m", "http.server", "8080"]

