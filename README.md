# DuyNguyen - Personal Portfolio (v3)

Welcome to the source code of my personal portfolio website, available at [duynch.com](https://duynch.com/). This project serves as a showcase of my skills, experiences, and technical blogs, with a focus on System Administration, DevOps, and Platform Engineering.

## Features

- **Hugo Framework:** Built with [Hugo](https://gohugo.io/) for lightning-fast static site generation.
- **Custom Design:** A completely custom, dependency-free theme crafted from scratch. 
- **Catppuccin Palette:** Inspired by the soothing [Catppuccin Mocha/Latte](https://github.com/catppuccin/catppuccin) color schemes for seamless Dark/Light mode switching.
- **Multilingual Support:** Full bilingual content in Vietnamese (`vi`) and English (`en`), complete with a smart language switcher that preserves the current context.
- **Responsive Layout:** Optimized for all screen sizes, featuring a beautiful masonry grid for projects and a sticky sidebar Table of Contents for technical blogs.
- **Interactive Elements:** Includes hover micro-animations, code block syntax highlighting, and custom copy-to-clipboard functionality.

## Tech Stack

- **SSG:** Hugo Extended
- **Styling:** Vanilla SCSS (compiled via Hugo pipes)
- **Scripting:** Vanilla JavaScript (ES6)

## Development Setup

To run this project locally, you need to install [Hugo Extended](https://gohugo.io/installation/).

1. Clone the repository:
   ```bash
   git clone https://github.com/duyaccel/duynch.git
   cd duynch
   ```

2. Start the Hugo development server:
   ```bash
   hugo server -D --bind 0.0.0.0
   ```

3. Open your browser and visit `http://localhost:1313`.

## CI/CD Pipeline

The deployment process follows a GitOps approach, separated into two repositories:

### Source Code Repo
- Commit and push changes to the `feature` branch.
- Open a Pull Request to merge into the `main` branch.

### Infra Repo
- Update the infrastructure manifest and image tag.
- Push changes to the `main` branch.
- FluxCD automatically reconciles and applies the changes to production.

## Author

- **Nguyễn Châu Hiếu Duy (DuyAccel)**
- [LinkedIn](https://linkedin.com/in/duynch) | [GitHub](https://github.com/duyaccel)

---
*Developed with ♥️ in Ho Chi Minh City.*
