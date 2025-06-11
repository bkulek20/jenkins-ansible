
from flask import Flask, render_template, request, redirect
import requests
import json
import os
import subprocess

app = Flask(__name__)

jenkins_ip = subprocess.check_output(
    ["terraform", "output", "-raw", "jenkins_ec2_ip"],
    cwd="./terraform" 
).decode().strip()

JENKINS_URL = f"http://{jenkins_ip}:8080/job/build-static-site/buildWithParameters"
JENKINS_USER = "admin"
JENKINS_TOKEN = "admin1234"

@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        env_name = request.form["env_name"]
        instance_type = request.form["instance_type"]
        template_type = request.form["template_type"]
        ttl = request.form["ttl"]


        with open("terraform.tfvars.json", "w") as f:
            json.dump({
                "environment_name": env_name,
                "instance_type": instance_type,
                "template_type": template_type,
                "ttl": ttl
            }, f)

        # Trigger jenkins
        requests.post(
            JENKINS_URL,
            auth=(JENKINS_USER, JENKINS_TOKEN),
            params={
                "env_name": env_name,
                "instance_type": instance_type,
                "template_type": template_type,
                "ttl": ttl
            }
        )

        return redirect("/status")

    return render_template("form.html")

@app.route("/status")
def status():
    return "Provisioning started. Check Jenkins and AWS for environment status."

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
