# YouTube Channel — Project Guidelines

## About

This workspace contains all content for a YouTube channel focused on **AWS, cloud security, and infrastructure as code**. Each top-level folder is a video project.

## Project Structure

Every video project follows this layout:

```
<Video Title>/
├── <Video Title>/          # Code/demo files (Terraform projects use same-name subfolder)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── terraform.tfvars.example
│   ├── README.md
│   ├── .gitignore
│   └── scripts/            # Helper scripts (user data, setup, etc.)
├── youtube/
│   ├── VIDEO_SCRIPT.md     # Full video script with timestamps, dialogue, and B-roll notes
│   ├── clips/              # Raw video clips
│   ├── thumbnail.png       # Thumbnail image
│   └── video.mp4           # Final exported video
```

For non-Terraform projects (e.g. guides, walkthroughs), the code folder may be named `demo/` instead.

## Video Script Format (VIDEO_SCRIPT.md)

Every script follows this exact structure:

1. **H1 title** matching the video title
2. **Video Metadata block** — Title, Description, Tags
3. **Timestamped sections** with `(start – ~end)` format:
   - INTRO — Hook the viewer, flash the final result
   - PREREQUISITES — What the viewer needs before starting
   - Architecture / overview section — Diagram or concept walkthrough
   - Code / demo walkthrough — VS Code or terminal, explain each file
   - Live deployment / demo — Full terminal walkthrough
   - CLEANUP — Tear down resources
   - OUTRO — CTA, link related videos, subscribe
4. **B-ROLL / OVERLAY IDEAS** — Table of timestamp → overlay suggestions
5. **DESCRIPTION BOX TEMPLATE** — Ready-to-paste YouTube description with links, timestamps, disclaimer, and hashtags

### Script Conventions

- Dialogue is in blockquotes (`> "spoken text"`)
- On-screen directions use bold: `**ON SCREEN:** Terminal`
- `**SHOW:**` indicates what to display on screen
- Code blocks show exact terminal commands the viewer will see
- Section timestamps use ranges: `(6:00 – ~8:30)`
- Videos are typically 8–13 minutes long
- Tone is direct, practical, and concise — no fluff

## Terraform Code Conventions

- **Provider:** AWS (`hashicorp/aws ~> 5.0`), region defaults to `eu-west-2`
- **Terraform version:** `>= 1.5.0`
- **File headers:** Comment block with project name: `# ------- <Project Name> - <File Purpose> -------`
- **Section separators:** `# -------------------- Section Name --------------------`
- **Tagging:** All resources tagged with `Name = "${var.project_name}-<resource>"`, plus default provider tags for `Project` and `ManagedBy = "Terraform"`
- **Security:**
  - IMDSv2 enforced on EC2 instances
  - EBS volumes encrypted
  - SSH/access locked to user-specified CIDR
  - Password auth disabled where applicable
- **Variables:** Sensible defaults for everything except security-sensitive values (e.g. `allowed_ssh_cidr`)
- **Outputs:** Instance ID, public IP, DNS, AMI ID, SSH connection command
- **Key generation:** `tls_private_key` + `local_file` with `0400` permissions
- **User data scripts:** Bash with `set -euo pipefail`, logged to `/var/log/<project>-setup.log`
- **ARM/Graviton support:** Default to `t4g.medium` (ARM) with x86 alternative commented

## README Conventions

Each code project includes a `README.md` with:

1. Title + one-line description
2. ASCII architecture diagram
3. Prerequisites table (tool + version)
4. Quick Start steps (clone → configure → deploy → connect → destroy)
5. File structure tree
6. Variables table (name, description, default)
7. What the setup script does (numbered list)
8. Security considerations
9. Estimated cost
10. Troubleshooting table (issue → solution)

## .gitignore (Terraform projects)

```
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
*.pem
terraform.tfvars
.DS_Store
Thumbs.db
```

## Channel Topics

- AWS services (EC2, VPC, IAM, Image Builder, SSM, etc.)
- Terraform / Infrastructure as Code
- Kali Linux and penetration testing
- Cloud security and hardening
- CLI tools and developer workflows

## Cross-Video Linking

Videos reference each other. When creating a new project, check existing projects for related content to link in the outro and description box.

Current projects:
- **AWS CLI Credentials Setup** — Prerequisite for any AWS project
- **Deploy a Kali Linux Machine in AWS** — Deploys a Kali EC2 instance with Terraform
- **Build a Custom Kali Image with EC2 Image Builder** — Builds a custom Kali AMI with baked-in tools
