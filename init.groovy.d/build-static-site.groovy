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

            export env_name="$env_name"
            export instance_type="$instance_type"
            export template_type="$template_type"
            export ttl="$ttl"

            echo "Provisioning environment: $env_name"
            echo "Instance Type: $instance_type"
            echo "Template: $template_type"
            echo "TTL: $ttl"

            echo "Workspace içerikleri:"
            ls -la "$WORKSPACE"

            echo "terraform.tfvars.json oluşturuluyor..."
cat <<EOF > "$WORKSPACE/terraform/terraform.tfvars.json"
{
"environment_name": "$env_name",
"instance_type": "$instance_type",
"template_type": "$template_type",
"ttl": "$ttl"
}
EOF

            cd "$WORKSPACE/terraform" || { echo "Terraform klasörüne girilemedi"; exit 1; }

            rm -rf .terraform .terraform.lock.hcl
            terraform init
            terraform refresh

            set +e
            terraform plan -detailed-exitcode -out=tfplan
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

            echo "Temizlik: terraform.tfvars.json siliniyor..."
            rm -f "$WORKSPACE/terraform/terraform.tfvars.json"
            ''')



        job.getBuildersList().add(shell)
        job.save()
    }
}



