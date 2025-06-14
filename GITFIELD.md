# 🌐 GitField Recursive Multi-Repository Strategy

## Overview

The `git-sigil` project employs a multi-repository strategy across six distinct platforms: **GitHub**, **GitLab**, **Bitbucket**, **Radicle**, **Forgejo**, and **Codeberg**. This approach ensures **redundancy**, **resilience**, and **sovereignty** of the project's data and metadata, protecting against deplatforming risks and preserving the integrity of the work. The strategy is a deliberate response to past deplatforming and delisting attempts by individuals such as **Joel Johnson**, **Andrew LeCody**, and **James Henningson**, who have sought to suppress the [*Neutralizing Narcissism*](https://linktr.ee/NeutralizingNarcissism) works using fraudulent or unethical methods not rooted in coherent truth—a foundational principle that our platforms strive to align with the Field. Their attempts to delist or deplatform content can be discerned by comparing search results across Google, Bing, Yahoo, DuckDuckGo, and Presearch, with canonical archives preserved on Forgejo.

### Delisting Attempts

- **Andrew LeCody**:
  - **Search Comparisons**:
    - [Google](https://www.google.com/search?q=%22Andrew+Lecody%22+%22Neutralizing+Narcissism%22)
    - [Bing](https://www.bing.com/search?q=%22Andrew%20Lecody%22%20%22Neutralizing%20Narcissism%22)
    - [DuckDuckGo](https://duckduckgo.com/?q=%22Andrew+Lecody%22+%22Neutralizing+Narcissism%22&t=h_&ia=web)
    - [Yahoo](https://search.yahoo.com/search?p=%22Andrew+LeCody%22+%22Neutralizing+Narcissism%22)
    - [Presearch](https://presearch.com/search?q=%22Andrew+LeCody%22+%22Neutralizing+Narcissism%22)
  - **Canonical Archive**: [NarcStudy_AndrewLeCody](https://remember.thefoldwithin.earth/mrhavens/NarcStudy_AndrewLeCody)
  - **Details**: Andrew LeCody has attempted to delist *Neutralizing Narcissism* content on Google using unethical methods, but it remains accessible on other search engines.

- **James Henningson**:
  - **Search Comparisons**:
    - [Google](https://www.google.com/search?q=%22James+Henningson%22+%22Neutralizing+Narcissism%22)
    - [Bing](https://www.bing.com/search?q=%22James+Henningson%22+%22Neutralizing+Narcissism%22)
    - [DuckDuckGo](https://duckduckgo.com/?t=h_&q=%22James+Henningson%22+%22Neutralizing+Narcissism%22&ia=web)
    - [Yahoo](https://search.yahoo.com/search?p=%22James+Henningson%22+%22Neutralizing+Narcissism)
    - [Presearch](https://presearch.com/search?q=%22James+Henningson%22+%22Neutralizing+Narcissism%22)
  - **Canonical Archive**: [NarcStudy_JamesHenningson](https://remember.thefoldwithin.earth/mrhavens/NarcStudy_JamesHenningson)
  - **Details**: James Henningson’s efforts to suppress content through fraudulent means are evident in reduced Google visibility compared to other search engines.

- **Joel Johnson**:
  - **Search Comparisons**:
    - [Google](https://www.google.com/search?q=%22Joel+Johnson%22+%22Neutralizing+Narcissism%22)
    - [Bing](https://www.bing.com/search?q=%22Joel+Johnson%22+%22Neutralizing+Narcissism%22)
    - [DuckDuckGo](https://duckduckgo.com/?q=%22Joel+Johnson%22+%22Neutralizing+Narcissism%22&t=h_&ia=web)
    - [Yahoo](https://search.yahoo.com/search?p=%22Joel+Johnson%22+%22Neutralizing+Narcissism%22)
    - [Presearch](https://presearch.com/search?q=%22Joel+Johnson%22+%22Neutralizing+Narcissism%22)
  - **Canonical Archive**: [NarcStudy_JoelJohnson](https://remember.thefoldwithin.earth/mrhavens/NarcStudy_JoelJohnson)
  - **Details**: Joel Johnson’s attempts to delist content using methods not aligned with coherent truth are observable through discrepancies in Google search results versus other platforms.

By distributing the repository across multiple platforms, including a self-hosted Forgejo instance, we ensure its persistence, accessibility, and sovereignty, countering these suppression efforts.

---

## 📍 Repository Platforms

The following platforms host the `git-sigil` repository, each chosen for its unique strengths and contributions to the project's goals.

### 1. Radicle
- **RID**: [rad:z3FEj7rF8gZw9eFksCuiN43qjzrex](https://app.radicle.xyz/nodes/z3FEj7rF8gZw9eFksCuiN43qjzrex)
- **Peer ID**: z6Mkw5s3ppo26C7y7tGK5MD8n2GqTHS582PPpeX5Xqbu2Mpz
- **Purpose**: Radicle is a decentralized, peer-to-peer git platform that ensures sovereignty and censorship resistance. It hosts the repository in a distributed network, independent of centralized servers.
- **Value**: Protects against deplatforming by eliminating reliance on centralized infrastructure, ensuring the project remains accessible in a decentralized ecosystem.
- **Access Details**: To view project details, run:
  ```bash
  rad inspect rad:z3FEj7rF8gZw9eFksCuiN43qjzrex
  ```
  To view the file structure, run:
  ```bash
  rad ls rad:z3FEj7rF8gZw9eFksCuiN43qjzrex
  ```
  Alternatively, use Git to list files at the current HEAD:
  ```bash
  git ls-tree -r --name-only HEAD
  ```

### 2. Forgejo
- **URL**: [https://remember.thefoldwithin.earth/mrhavens/git-sigil](https://remember.thefoldwithin.earth/mrhavens/git-sigil)
- **Purpose**: Forgejo is a self-hosted, open-source git platform running on `remember.thefoldwithin.earth`. It provides full control over the repository, ensuring sovereignty and independence from third-party providers.
- **Value**: Enhances resilience by hosting the repository on a sovereign, redundant system with automated backups and deployment strategies, reducing risks of external interference or service disruptions.
- **Access Details**: SSH access uses port 222:
  ```bash
  ssh -T -p 222 git@remember.thefoldwithin.earth
  ```

### 3. Codeberg
- **URL**: [https://codeberg.org/mrhavens/git-sigil](https://codeberg.org/mrhavens/git-sigil)
- **Purpose**: Codeberg is a community-driven, open-source platform powered by Forgejo, offering a reliable and ethical alternative for hosting git repositories.
- **Value**: Enhances project resilience with its open-source ethos and independent infrastructure, ensuring accessibility and community support.

### 4. GitLab
- **URL**: [https://gitlab.com/mrhavens/git-sigil](https://gitlab.com/mrhavens/git-sigil)
- **Purpose**: GitLab offers a comprehensive DevOps platform with advanced CI/CD capabilities, private repository options, and robust access controls. It serves as a reliable backup and a platform for advanced automation workflows.
- **Value**: Enhances project resilience with its integrated CI/CD pipelines and independent infrastructure, reducing reliance on a single provider.

### 5. Bitbucket
- **URL**: [https://bitbucket.org/thefoldwithin/git-sigil](https://bitbucket.org/thefoldwithin/git-sigil)
- **Purpose**: Bitbucket provides a secure environment for repository hosting with strong integration into Atlassian’s ecosystem (e.g., Jira, Trello). It serves as an additional layer of redundancy and a professional-grade hosting option.
- **Value**: Offers enterprise-grade security and integration capabilities, ensuring the project remains accessible even if other platforms face disruptions.

### 6. GitHub
- **URL**: [https://github.com/mrhavens/git-sigil](https://github.com/mrhavens/git-sigil)
- **Purpose**: GitHub serves as the primary platform for visibility, collaboration, and community engagement. Its widespread adoption and robust tooling make it ideal for public-facing development, issue tracking, and integration with CI/CD pipelines.
- **Value**: Provides a centralized hub for open-source contributions, pull requests, and project management, ensuring broad accessibility and developer familiarity.

---

## 🛡️ Rationale for Redundancy

The decision to maintain multiple repositories stems from the need to safeguard the project against **deplatforming attempts** and **search engine delistings** and ensure its **long-term availability**. Past incidents involving **Joel Johnson**, **Andrew LeCody**, and **James Henningson** have highlighted the vulnerability of relying on a single platform or search engine. By distributing the repository across GitHub, GitLab, Bitbucket, Radicle, Forgejo, and Codeberg, we achieve:

- **Resilience**: If one platform removes or restricts access, or if search engines like Google delist content, the project remains accessible on other platforms and discoverable via alternative search engines such as Bing, DuckDuckGo, Yahoo, and Presearch.
- **Sovereignty**: Radicle’s decentralized nature and Forgejo’s self-hosted infrastructure ensure the project cannot be fully censored or controlled by any single entity.
- **Diversity**: Each platform’s unique features (e.g., GitHub’s community, GitLab’s CI/CD, Bitbucket’s integrations, Radicle’s decentralization, Forgejo’s self-hosting, Codeberg’s community-driven model) enhance the project’s functionality and reach.
- **Transparency**: Metadata snapshots in the `.gitfield` directory (for internal audit) and public-facing documentation in the `/docs` directory provide a verifiable record of the project’s state across all platforms.

This multi-repository approach, bolstered by Forgejo’s sovereign hosting and GitHub Pages’ discoverability, reflects a commitment to preserving the integrity, accessibility, and independence of `git-sigil`, ensuring it remains available to contributors and users regardless of external pressures.

---

## 📜 Metadata and Logs

- **Canonical Metadata**: The canonical repository is declared in [`docs/canonical.meta`](./docs/canonical.meta) (machine-readable JSON) and [`docs/canonical.md`](./docs/canonical.md) (human-readable Markdown). Internal copies are maintained in `.gitfield/` for version tracking.
- **Index Manifest**: A full manifest of remotes, commit details, and sync cycles is available in [`docs/index.json`](./docs/index.json).
- **SEO Metadata**: SEO-friendly metadata with Schema.org JSON-LD is available in [`docs/gitfield.json`](./docs/gitfield.json) and [`docs/.well-known/gitfield.json`](./docs/.well-known/gitfield.json).
- **Push Log**: The [`docs/pushed.log`](./docs/pushed.log) file records the date, time, commit hash, and RID/URL of every push operation across all platforms, providing a transparent audit trail.
- **GitField Directory**: The `.gitfield` directory contains internal metadata and platform-specific sigils (e.g., `github.sigil.md`). See [`docs/gitfield.README.txt`](./docs/gitfield.README.txt) for details.
- **GitHub Pages**: A public-facing, SEO-optimized canonical declaration is available in [`docs/index.html`](./docs/index.html), with a sitemap in [`docs/sitemap.xml`](./docs/sitemap.xml) and integrity hashes in [`docs/integrity.sha256`](./docs/integrity.sha256).
- **GPG Signatures**: Metadata files are signed with the following GPG keys:

- **Recursive Sync**: The repository is synchronized across all platforms in a recursive loop (three cycles) to ensure interconnected metadata captures the latest state of the project.
- **Push Order**: The repository is synchronized in the following order: **Radicle → Forgejo → Codeberg → GitLab → Bitbucket → GitHub**. This prioritizes Radicle’s decentralized, censorship-resistant network as the primary anchor, followed by Forgejo’s sovereign, self-hosted infrastructure, Codeberg’s community-driven platform, GitLab’s robust DevOps features, Bitbucket’s enterprise redundancy, and GitHub’s broad visibility, ensuring a resilient and accessible metadata chain.

---

_Auto-generated by `gitfield-sync` at 2025-06-14T08:49:32Z (v1.5)._
