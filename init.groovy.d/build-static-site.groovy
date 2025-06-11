import jenkins.model.*
import hudson.model.*
import hudson.plugins.git.*
import hudson.tasks.Shell

def jenkins = Jenkins.getInstanceOrNull()
if (jenkins != null) {
    def jobName = "build-static-site"

    if (jenkins.getItem(jobName) == null) {
        def job = jenkins.createProject(FreeStyleProject, jobName)
        job.setDescription("Builds and runs the static Docker site.")

        job.addProperty(new ParametersDefinitionProperty(
            new StringParameterDefinition("env_name", "dev"),
            new StringParameterDefinition("instance_type", "t3.micro"),
            new StringParameterDefinition("template_type", "web"),
            new StringParameterDefinition("ttl", "24h")
        ))

        def gitSCM = new GitSCM(
            [new UserRemoteConfig("https://github.com/bkulek20/jenkins-ansible.git", null, null, null)],
            [new BranchSpec("*/main")],
            false, Collections.emptyList(), null, null, Collections.emptyList()
        )
        job.setScm(gitSCM)

        def shell = new Shell('''#!/bin/bash
            set -e

            which aws || echo "AWS CLI not found"

            echo "Provisioning environment: $env_name"
            echo "Instance Type: $instance_type"
            echo "Template: $template_type"
            echo "TTL: $ttl"

            echo "Workspace içerikleri:"
            ls -la "$WORKSPACE"


            cd "$WORKSPACE/terraform" || { echo "Terraform klasörüne girilemedi"; exit 1; }
            echo "PWD: $(pwd)"

            echo "Terraform içerikleri:"
            ls -la "$WORKSPACE/terraform"

            echo "Şu anki dizin:"
            pwd


            terraform init
            terraform refresh

            set +e
            terraform plan -detailed-exitcode -var="environment_name=$env_name" -var="instance_type=$instance_type" -var="ttl=$ttl" -out=tfplan
            plan_exit_code=$?
            set -e

            terraform show -no-color tfplan > plan_output.txt
            cat plan_output.txt

            if [ $plan_exit_code -eq 2 ]; then
                echo "Terraform apply yapılıyor..."
                terraform apply -auto-approve tfplan
            elif [ $plan_exit_code -eq 0 ]; then
                echo "Değişiklik yok, apply yapılmayacak."
            else
                echo "Terraform plan hatası. Exit code: $plan_exit_code"
                exit $plan_exit_code
            fi

            EC2_PUBLIC_IP=$(terraform output -raw public_ip)
            echo "EC2 Public IP: $EC2_PUBLIC_IP"

            echo "[web]" > ../ansible/inventory.ini
            echo "$EC2_PUBLIC_IP" >> ../ansible/inventory.ini

            cd ../ansible
            ansible-playbook -i inventory.ini "$template_type.yml"
            ''')


        job.getBuildersList().add(shell)
        job.save()
    }
}



