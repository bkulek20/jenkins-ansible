import jenkins.model.*
import hudson.security.csrf.DefaultCrumbIssuer

Jenkins.instance.setCrumbIssuer(null)
Jenkins.instance.save()
