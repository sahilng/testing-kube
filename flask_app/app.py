from flask import Flask, jsonify, Response
from flask_sqlalchemy import SQLAlchemy
import os
import socket
import matplotlib.pyplot as plt
import io

app = Flask(__name__)

# Database configuration
POSTGRES_USER = os.getenv('POSTGRES_USER', 'yourusername')
POSTGRES_PASSWORD = os.getenv('POSTGRES_PASSWORD', 'yourpassword')
POSTGRES_DB = os.getenv('POSTGRES_DB', 'yourdb')
POSTGRES_HOST = os.getenv('POSTGRES_HOST', 'postgres-service')
POSTGRES_PORT = os.getenv('POSTGRES_PORT', '5432')

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Define the PodRequest model to track requests by pod
class PodRequest(db.Model):
    __tablename__ = 'pod_requests'
    id = db.Column(db.Integer, primary_key=True)
    pod_name = db.Column(db.String(100), nullable=False)
    request_count = db.Column(db.Integer, nullable=False, default=1)

# Route to track requests and generate a bar chart
@app.route('/')
def index():
    hostname = socket.gethostname()

    # Update the request count for the pod
    pod_request = PodRequest.query.filter_by(pod_name=hostname).first()
    if pod_request:
        pod_request.request_count += 1
    else:
        pod_request = PodRequest(pod_name=hostname, request_count=1)
        db.session.add(pod_request)
    db.session.commit()

    # Get the request count per pod
    pod_counts = {pr.pod_name: pr.request_count for pr in PodRequest.query.order_by(PodRequest.pod_name).all()}

    # Generate a bar chart
    plt.figure(figsize=(10, 6))
    plt.bar(pod_counts.keys(), pod_counts.values(), color='skyblue')
    plt.xlabel('Pod Name')
    plt.ylabel('Request Count')
    plt.title('Requests per Pod')

    # Save the chart to a BytesIO object and serve it as an image
    img = io.BytesIO()
    plt.savefig(img, format='png')
    img.seek(0)
    plt.close()

    return Response(img, mimetype='image/png')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
