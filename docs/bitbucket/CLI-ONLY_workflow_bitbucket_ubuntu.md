## 🧭 FULL CLI-ONLY WORKFLOW (Ubuntu + Bitbucket)

---

### 🔹 Step 1 — Install prerequisites

```bash
# Install Git
sudo apt update
sudo apt install git -y

# Install cURL and OpenSSH if not already
sudo apt install curl openssh-client -y
```

---

### 🔹 Step 2 — Create a Bitbucket account

Go to: [https://bitbucket.org/account/signup](https://bitbucket.org/account/signup)

> You’ll need to verify email, set username, and generate an **App Password** with at least:
>
> * `Repository` (read/write)
> * `SSH` (read/write)

---

### 🔹 Step 3 — Set your global Git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

---

### 🔹 Step 4 — Generate and register your SSH key

```bash
# Generate SSH key (if not already present)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com" -f ~/.ssh/id_rsa -N ""

# Start SSH agent
eval "$(ssh-agent -s)"

# Add key to agent
ssh-add ~/.ssh/id_rsa
```

Then copy your public key:

```bash
cat ~/.ssh/id_rsa.pub
```

Paste it into:
🔐 **Bitbucket → Personal settings → SSH keys → Add key**

---

### 🔹 Step 5 — Create your local project

```bash
mkdir myproject
cd myproject
git init
echo "# My Bitbucket Project" > README.md
git add .
git commit -m "Initial commit"
```

---

### 🔹 Step 6 — Create a new Bitbucket repo (via browser)

Unfortunately, **Bitbucket does not have a CLI tool** for creating repositories.
➡️ Go to: [https://bitbucket.org/repo/create](https://bitbucket.org/repo/create)
Create a **public** or **private** repo named the same as your folder (e.g., `myproject`).

> Ensure it's an **empty repo** (don’t initialize with README or .gitignore).

---

### 🔹 Step 7 — Link local repo to Bitbucket via SSH

```bash
# Use the SSH format:
git remote add origin git@bitbucket.org:your_username/myproject.git

# Verify connection
ssh -T git@bitbucket.org
```

---

### 🔹 Step 8 — Push to Bitbucket

```bash
# Set upstream branch
git push -u origin master  # or main
```

---

### 🔹 Step 9 — Make further commits

```bash
# Edit files
nano something.txt

# Stage, commit, push
git add .
git commit -m "Updated something"
git push
```

---

### 🔹 Bonus — Clone a Bitbucket repo

```bash
# Clone using SSH
git clone git@bitbucket.org:your_username/your_repo.git
```

---

### 🔒 Tip — Use SSH for all Bitbucket CLI work

Bitbucket heavily rate-limits HTTPS for CLI usage without app passwords.
Always prefer `SSH` for full CLI-based workflows.

---
