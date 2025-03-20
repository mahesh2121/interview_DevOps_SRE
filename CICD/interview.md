# 🚀 CI/CD & Scripting

## ✅ Explain CI/CD.

### **What is CI/CD?**
CI/CD (Continuous Integration and Continuous Deployment/Delivery) is a DevOps practice that automates the software development lifecycle.

### **Continuous Integration (CI)**
- Developers frequently merge code into a shared repository.
- Automated builds and tests run to detect issues early.
- Tools: Jenkins, GitHub Actions, GitLab CI, CircleCI.

### **Continuous Deployment/Delivery (CD)**
- **Continuous Delivery** ensures that code is always in a deployable state, requiring manual approval for release.
- **Continuous Deployment** automatically deploys every successful build to production.
- Tools: AWS CodePipeline, ArgoCD, Spinnaker, Kubernetes.

### **CI/CD Pipeline Workflow**
1. **Code** → Developers push changes to a repository.
2. **Build** → Code is compiled and dependencies are installed.
3. **Test** → Automated tests validate the code.
4. **Deploy** → Application is deployed to staging/production.
5. **Monitor** → Performance and logs are analyzed.

---

## ✅ Bash Script to Get Directory Path, Check Existence, and Create If Not Present

```bash
#!/bin/bash

# Prompt user for directory path
echo "Enter directory path:"
read dir_path

# Check if the directory exists
if [ -d "$dir_path" ]; then
    echo "Directory already exists: $dir_path"
else
    # Create the directory
    mkdir -p "$dir_path"
    echo "Directory created: $dir_path"
fi
```

### **Usage:**
```bash
chmod +x check_directory.sh
./check_directory.sh
```

This script prompts the user for a directory path, checks if it exists, and creates it if it doesn’t. 🚀
