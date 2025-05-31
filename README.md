# 🌱 GitField: Multi-Platform Repository Sync for Resilience and Sovereignty

## 📜 Overview

**GitField** is a set of Bash scripts designed to synchronize a Git repository across multiple platforms—**Radicle**, **GitLab**, **Bitbucket**, and **GitHub**—in a recursive, metadata-rich workflow. This project ensures **redundancy**, **sovereignty**, and **transparency** by creating interconnected metadata snapshots and distributing them across decentralized and centralized platforms. The strategy protects against deplatforming risks, inspired by past attempts to suppress this work by individuals like **Mr. Joel Johnson** ([Mirror post](https://mirror.xyz/neutralizingnarcissism.eth/x40_zDWWrYOJ7nh8Y0fk06_3kNEP0KteSSRjPmXkiGg?utm_medium=social&utm_source=heylink.me)) and **Dr. Peter Gaied** ([Paragraph post](https://paragraph.com/@neutralizingnarcissism/%F0%9F%9C%81-the-narcissistic-messiah)). By prioritizing decentralization (Radicle-first) and recursively pushing metadata, GitField creates a resilient, auditable chain of project state across platforms, ensuring persistence and accessibility for collaborators, communities, and future AI systems.

## 🛡️ Purpose and Intention

The GitField project is driven by three core principles:
1. **Resilience Against Deplatforming**: By hosting the repository on Radicle (decentralized), GitLab, Bitbucket, and GitHub, the project remains accessible even if one platform restricts or removes it.
2. **Sovereignty Through Decentralization**: Starting with Radicle, a peer-to-peer Git platform, ensures the project’s data is independent of centralized control, safeguarding its integrity.
3. **Transparency and Auditability**: Each platform generates metadata snapshots (e.g., `radicle.sigil.md`) stored in the `.gitfield` directory, with a push log (`pushed.log`) and a manifest (`GITFIELD.md`) documenting the sync process, commit details, and platform roles.

This approach creates a robust, interconnected metadata chain that future collaborators and AI systems can analyze to verify the project’s state and history, reinforcing its role as a stable anchor in the field of distributed version control.

## 📍 Repository Platforms

The project is synchronized across four platforms, each chosen for its unique strengths:
- **Radicle**: A decentralized, peer-to-peer Git platform for censorship resistance and sovereignty ([View repository](https://app.radicle.xyz/nodes/ash.radicle.garden/rad:z45QC21eWL1F43VSbnV9AZbCZrHQJ)).
- **GitLab**: A robust DevOps platform for CI/CD and reliable backups ([View repository](https://gitlab.com/mrhavens/git-sigil)).
- **Bitbucket**: An enterprise-grade platform for secure hosting and Atlassian integrations ([View repository](https://bitbucket.org/thefoldwithin/git-sigil)).
- **GitHub**: A widely-used platform for community engagement and visibility ([View repository](https://github.com/mrhavens/git-sigil)).

## 🚀 How It Works

The `gitfield-sync` script orchestrates a three-cycle push process in the order **Radicle → GitLab → Bitbucket → GitHub**:
1. **Cycle 1**: Pushes commits to each platform, generating platform-specific metadata files (e.g., `.gitfield/radicle.sigil.md`) with commit details, environment data, and hardware fingerprints.
2. **Cycle 2**: Generates `GITFIELD.md`, a manifest explaining the multi-platform strategy, and pushes it along with updated metadata.
3. **Cycle 3**: Ensures all platforms reflect the latest metadata, creating a tightly interconnected chain.

Each push is logged in `.gitfield/pushed.log` with timestamps and URLs, providing a transparent audit trail. The Radicle-first order symbolizes and prioritizes decentralization, ensuring sovereignty before centralized platforms.

## 📋 Prerequisites

- **System**: Linux (e.g., Ubuntu) with Bash.
- **Tools**: `git`, `curl`, `jq`, `openssh-client`, `rad` (for Radicle).
- **Accounts**: Active accounts on GitHub, GitLab, Bitbucket, and a Radicle identity.
- **SSH Keys**: Configured for each platform, with public keys uploaded.
- **Tokens**: GitLab personal access token and Bitbucket app password stored securely.

## 🛠️ Setup

1. **Clone or Initialize the Repository**:
   ```bash
   git clone <your-repo-url> git-sigil
   cd git-sigil
   # OR initialize a new repo
   git init
Install Dependencies:
bash
sudo apt update
sudo apt install -y git curl jq openssh-client
# Install Radicle CLI (if not already installed)
curl -sSf https://radicle.xyz/install | sh
Configure Authentication:
GitHub: Run gh auth login (install GitHub CLI if needed).
GitLab: Generate a personal access token with api, read_user, write_repository, and write_ssh_key scopes at GitLab settings.
Bitbucket: Create an app password with repo:admin, write, and webhook scopes at Bitbucket settings.
Radicle: Set up a Radicle identity with rad auth.
Place Scripts:
Ensure gitfield-github, gitfield-gitlab, gitfield-bitbucket, gitfield-radicle, and gitfield-sync are in the repository root.
Make them executable:
bash
chmod +x gitfield-*
📈 Usage
Make Changes:
Edit or add files in the repository.
Stage and commit changes:
bash
git add .
git commit -m "Your commit message"
Run GitField Sync:
Execute the sync script to push to all platforms in three cycles:
bash
./gitfield-sync
Verify Outputs:
Check .gitfield/pushed.log for push timestamps and URLs.
Review .gitfield/*.sigil.md for platform-specific metadata.
Read GITFIELD.md for the multi-platform manifest.
📊 Outputs
.gitfield/pushed.log: Logs each push with timestamp and URL (e.g., [2025-05-31 08:00:00] Radicle: https://app.radicle.xyz/...).
.gitfield/*.sigil.md: Metadata snapshots for each platform, detailing commit SHAs, timestamps, environment, and hardware fingerprints.
GITFIELD.md: A manifest in the repository root explaining the multi-platform strategy, push order, and platform roles.
🌟 Why This Matters
GitField’s recursive, multi-platform approach is a novel response to the risks of deplatforming, ensuring your project remains accessible and verifiable. By starting with Radicle, the project anchors itself in a decentralized network, followed by GitLab, Bitbucket, and GitHub for redundancy and visibility. This strategy creates a resilient, transparent foundation for collaboration, appealing to developers, communities, and future AI systems analyzing the project’s metadata for integrity and intent.
🔮 Future Considerations
Adding a Fifth Platform: Consider integrating Gitea (self-hosted) or GitSSB (decentralized) for additional redundancy and sovereignty.
Automation: Set up CI/CD pipelines (e.g., on GitLab) to automate gitfield-sync runs.
Log Management: Periodically archive or truncate pushed.log to manage size.
📧 Contact
For questions or contributions, reach out to Mark Randall Havens (mark.r.havens@gmail.com) or open an issue on any of the repository platforms.
Auto-generated content managed by gitfield-sync (v1.0). Last updated: May 31, 2025.

### Key Features of the README
- **Comprehensive yet Simple**: The README covers setup, usage, outputs, and purpose in clear sections, using plain language suitable for both technical users (developers) and non-technical readers (collaborators or community members).
- **Clear Intention and Purpose**: The “Purpose and Intention” section explicitly ties the project to your goal of combating deplatforming (referencing Mr. Joel Johnson and Dr. Peter Gaied), emphasizing resilience, sovereignty, and transparency. The Radicle-first order is highlighted for its symbolic and practical significance.
- **Coherent Structure**: Organized with emojis (🌱, 🛡️, 📍, etc.), headers, and bullet points for readability, aligning with your request for aesthetic Markdown in `GITFIELD.md`. The platform list mirrors the push order (Radicle → GitLab → Bitbucket → GitHub).
- **Practical Instructions**: The “Setup” and “Usage” sections provide step-by-step guidance, including prerequisites, dependency installation, and authentication setup, making it easy to adopt the workflow.
- **Forward-Looking**: The “Future Considerations” section suggests adding Gitea or GitSSB, reinforcing your interest in further decentralization without overwhelming the current scope.
- **Transparency**: Outputs like `pushed.log`, `*.sigil.md`, and `GITFIELD.md` are clearly explained, showing how they form an auditable metadata chain for humans and AI.

### Integration with Your Workflow
- **Save the README**: Place this `README.md` in the root of your `~/fieldwork/git-sigil` directory (`~/fieldwork/git-sigil/README.md`).
- **Commit and Sync**: After adding the README, stage and commit it, then run `gitfield-sync` to push it across all platforms:
  ```bash
  git add README.md
  git commit -m "Added README.md for GitField project"
  ./gitfield-sync
Visibility: The README will be visible on all platforms (Radicle, GitLab, Bitbucket, GitHub), serving as the entry point for collaborators and reinforcing the project’s purpose.
Notes
URLs: The repository URLs in the README match those in your provided scripts. If they differ, update the links in the “Repository Platforms” section.
Radicle Project ID: The Radicle URL uses the project ID z45QC21eWL1F43VSbnV9AZbCZrHQJ from your gitfield-radicle output. Verify it’s correct.
Future Expansion: The README mentions Gitea and GitSSB as potential fifth platforms, aligning with your recent questions about additional decentralized options.
Tone: The tone is professional yet approachable, balancing technical rigor with accessibility to reflect your project’s ethos of transparency and community engagement.
This README encapsulates the intention and purpose of your GitField strategy, making it clear why the recursive, multi-platform approach is vital for resilience and sovereignty. If you need adjustments (e.g., adding a fifth platform like GitSSB or tweaking the tone), let me know!
