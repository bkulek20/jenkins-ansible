resource "aws_key_pair" "bkulek_key" {
  key_name   = "bkulek-key"
  #public_key = file("~/.ssh/id_rsa.pub")
  public_key = file("${path.module}/bkulek-key.pub")


}

resource "aws_launch_template" "example_server" {
  image_id                    = "ami-02b7d5b1e55a7b5f1" #eu-central-1
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.bkulek_key.key_name
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]



    block_device_mappings {
        device_name = "/dev/xvda"

        ebs {
        volume_size = 16      
        volume_type = "gp3"
        delete_on_termination = true
        }
    }

 
        user_data = base64encode(<<-EOF
            #!/bin/bash
            exec > /var/log/user-data.log 2>&1
            set -x

            yum update -y
            yum install -y git docker
            systemctl start docker
            systemctl enable docker
            usermod -aG docker ec2-user

            cd /home/ec2-user
            git clone --branch main https://github.com/bkulek20/jenkins-ansible.git
            cd jenkins-ansible


            sleep 15
            

            docker build --build-arg DOCKER_GID=$(getent group docker | cut -d: -f3) -t myjenkins .


            docker stop jenkins || true
            docker rm jenkins || true

            docker run -d \
            --name jenkins \
            --network host \
            -v jenkins_home:/var/jenkins_home \
            -v /home/ec2-user/jenkins-ansible/casc_configs/jenkins.yaml:/var/jenkins_home/jenkins.yaml \
            -v /var/run/docker.sock:/var/run/docker.sock \
            -v /home/ec2-user/.ssh/id_rsa:/root/.ssh/id_rsa \
            -e CASC_JENKINS_CONFIG=/var/jenkins_home/jenkins.yaml \
            -e JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
            myjenkins


    EOF
    )

 


  tags = {
    Name = "bkulek-bootcamp-${var.environment_name}"
    expire_at  = "2025-06-12T20:00:00Z"  # UTC formatta TTL değeri
  }


}



# docker run -d -p 8000:80 nginx

resource "aws_instance" "example_instance" {
  launch_template {
    
    id      = aws_launch_template.example_server.id
    version = "$Latest"
  }
  iam_instance_profile = aws_iam_instance_profile.jenkins_profile.name



  tags = {
    Name = "bkulek-bootcamp-ec2"
  }
}




resource "aws_security_group" "jenkins_sg" {
  #name        = "jenkins_sg"
  name_prefix = "jenkins_sg_${var.environment_name}_"
  description = "Allow SSH and Jenkins"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}


resource "aws_iam_role" "jenkins_terraform_role" {
  name = "jenkins-terraform-role-${var.environment_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }],
    
  })
}

resource "aws_iam_role_policy" "jenkins_inline_policy" {
  name = "jenkins-inline-policy"
  role = aws_iam_role.jenkins_terraform_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:GetRole",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy",
          "iam:PassRole",
          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:TagRole",
          "iam:TagPolicy",
          "iam:ListRolePolicies",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListInstanceProfilesForRole",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:DeleteRole",
          "iam:ListPolicyVersions",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",
          "iam:ListEntitiesForPolicy",
          "iam:CreateInstanceProfile",
          "iam:DetachRolePolicy",
          "iam:TagInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ],
        Resource = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ec2" {
  role       = aws_iam_role.jenkins_terraform_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "s3" {
  role       = aws_iam_role.jenkins_terraform_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "vpc" {
  role       = aws_iam_role.jenkins_terraform_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.jenkins_terraform_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-instance-profile"
  role = aws_iam_role.jenkins_terraform_role.name
}
