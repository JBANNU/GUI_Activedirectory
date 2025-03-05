from flask import Flask, request, jsonify, send_from_directory, render_template, redirect, url_for, session, flash
from flask_cors import CORS
from ldap3 import Connection, Server, ALL, NTLM, SIMPLE, SYNC, ASYNC
import subprocess
import os
from functools import wraps  # Import wraps
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
CORS(app)

# --- Configuration ---
app.config['SECRET_KEY'] = os.urandom(24)  # Replace with a long, random string.
STATIC_DIR = 'static'
SCRIPTS_DIR = 'powershell_scripts'

# LDAP Configuration (Move credentials to environment variables!)
app.config['LDAP_SERVER'] = os.environ.get('AD_SERVER', 'win-dsi08mm8fdk.uamtest.com')  # Replace with actual server
app.config['LDAP_BASE_DN'] = os.environ.get('AD_BASE_DN', 'dc=UAMtest,dc=com')  # Replace with actual Base DN
LDAP_USER_SEARCH_FILTER = "(&(objectClass=user)(sAMAccountName={username}))"
LDAP_BIND_USER_FORMAT = "{domain}\\{username}"
LDAP_DOMAIN = "UAMtest.com"  # Your AD domain

def authenticate(username, password):
    """Authenticates a user against Active Directory using ldap3."""
    try:
        bind_user = LDAP_BIND_USER_FORMAT.format(username=username, domain=LDAP_DOMAIN)
        server = Server(app.config['LDAP_SERVER'], get_info=ALL)
        conn = Connection(server, user=bind_user, password=password, authentication=NTLM, auto_bind=True)

        if conn.bind():
            print(f"Authentication successful for {username}")
            conn.unbind()
            return True
        else:
            print(f"Authentication failed: {conn.result}")
            print(conn.last_error)
            conn.unbind()
            return False

    except Exception as e:
        print(f"LDAP Error: {e}")
        return False

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Handles the login process."""
    error = None
    if request.method == "POST":
        username = request.form["username"]
        password = request.form["password"]

        if authenticate(username, password):
            session["username"] = username
            return redirect(url_for("Menu"))
        else:
            error = "Invalid username or password"

    return render_template("login.html", error=error)

@app.route('/Menu')
def Menu():
    """Serves the AD_Script_final.html file after login."""
    if "username" in session:
        return send_from_directory(STATIC_DIR, 'AD_Script_final.html')
    else:
        return redirect(url_for("login"))

@app.route('/logout')
def logout():
    """Logs the user out."""
    session.pop("username", None)
    return redirect(url_for("login"))

@app.route('/')  # Define a route for the root URL
def index():
    """Redirects to the login page."""
    return redirect(url_for("login"))

@app.route('/api')
def api_message():
    """API message."""
    return "<h1>This is an Application Programming Interface only</h1>"

@app.route('/api/powershell', methods=['POST'])
def execute_powershell():
    """Executes PowerShell scripts after authentication."""
    if "username" not in session:  # Protect the route
        return jsonify({'error': 'Authentication required'}), 401  # Unauthorized

    data = request.get_json()
    script_name = data.get('scriptName')

    VALID_SCRIPTS = ['createUser', 'resetPassword', 'disableUser', 'addUserToGroup', 'removeUserFromGroup', 'deleteUser', 'groupCreation']

    if script_name not in VALID_SCRIPTS:
        print("Invalid script name detected:", script_name)
        return jsonify({'error': 'Invalid script name.  Please check the script name.'}), 400

    script_path = os.path.join(SCRIPTS_DIR, f"{script_name}.ps1")

    if not os.path.exists(script_path):
        custom_error_message = "Check the PowerShell script file name; the file was not found."
        return jsonify({'exit_code': 1, 'error': custom_error_message, 'output': '', 'stderr': ''}), 400

    try:
        process = subprocess.Popen(
            ['powershell', '-ExecutionPolicy', 'Bypass', '-File', script_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            shell=True  # Required for ExecutionPolicy Bypass on some systems
        )
        stdout, stderr = process.communicate()

        stdout_str = stdout.decode('utf-8')
        stderr_str = stderr.decode('utf-8')
        exit_code = process.returncode

        print("PowerShell Output:", stdout_str)
        print("PowerShell Errors:", stderr_str)

        return jsonify({
            'exit_code': exit_code,
            'output': stdout_str,
            'error': stderr_str
        })

    except Exception as e:
        error_message = str(e)
        print("PowerShell Execution Error:", error_message)
        return jsonify({
            'exit_code': 1,
            'error': error_message,
            'output': '',
            'stderr': ''
        }), 500

@app.route('/api/powershell/info', methods=['GET'])
def powershell_info():
    """Provides information about PowerShell scripts."""
    return "<h1>Use with caution.</h1><p>Each step is recorded.</p>"

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0')