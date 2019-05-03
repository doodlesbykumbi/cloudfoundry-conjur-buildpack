"""Cloud Foundry test"""
from flask import Flask
import os

app = Flask(__name__)

port = int(os.getenv("PORT"))

@app.route('/')
def hello_world():
    return '''
      <h1>Visit us @ www.conjur.org!</h1>

      <h3>Space-wide Secrets</h3>
      <p>Database Username: {username}</p>
      <p>Database Password: {password}</p>
    '''.format(username=os.environ['SPACE_USERNAME'], password=os.environ['SPACE_PASSWORD'])
    
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=port)