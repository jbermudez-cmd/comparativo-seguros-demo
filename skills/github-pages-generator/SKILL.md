# Skill: GitHub Pages Generator

Create and deploy professional landing pages to GitHub Pages with automated workflows, custom domains, and modern templates.

## When to Use

Use this skill when you need to:
- Create a public portfolio or demo page from HTML/CSS/JS files
- Deploy documentation sites automatically from Markdown
- Set up landing pages for projects with custom domains
- Generate multi-page static sites with navigation
- Create branded presentations or showcases

## What It Does

1. Initializes Git repository with proper structure
2. Creates professional HTML templates (Tailwind CSS)
3. Configures GitHub Pages settings via API
4. Handles custom domain setup (CNAME, DNS)
5. Sets up automated deployments (GitHub Actions)
6. Generates responsive, dark-mode ready pages

## Prerequisites

- GitHub account with Personal Access Token
- Git installed locally or server access
- Optional: Custom domain DNS access

## Usage Examples

### Basic: Deploy Single HTML Page

```bash
# In your workspace directory
github-pages deploy \
  --source ./my-project \
  --repo my-username/my-project \
  --title "My Project Demo" \
  --description "A showcase of my amazing project"
```

### Advanced: Multi-page Site with Custom Domain

```bash
github-pages deploy \
  --source ./site \
  --repo my-username/portfolio \
  --template modern-dark \
  --domain portfolio.mycompany.com \
  --analytics GA-XXXXXXXX \
  --seo
```

### Using in OpenClaw

```javascript
// Deploy a demo page from generated files
const result = await githubPages.deploy({
  source: '/home/ubuntu/workspace/demo-files',
  repo: 'jbermudez-cmd/demo-project',
  token: process.env.GITHUB_TOKEN,
  title: 'Demo: AI Automation System',
  template: 'tech-showcase',
  pages: ['index', 'features', 'contact']
});

console.log('Live at:', result.url);
```

## Available Templates

| Template | Use Case | Features |
|----------|----------|----------|
| `minimal` | Quick demos | Clean, single-page |
| `tech-showcase` | Product demos | Hero, features, code blocks |
| `portfolio` | Personal branding | Gallery, about, contact |
| `documentation` | API/docs sites | Sidebar nav, search-ready |
| `landing-sales` | Conversion pages | CTAs, testimonials, pricing |

## Configuration

### environment variables

```bash
GITHUB_TOKEN=ghp_xxxxxxxxxx
GITHUB_USERNAME=your-username
GITHUB_EMAIL=your@email.com
```

### Custom Template Structure

```
my-template/
├── index.html      # Main template
├── css/
│   └── style.css   # Custom styles
├── js/
│   └── main.js     # Interactivity
└── assets/         # Images, fonts
```

## Common Workflows

### 1. Deploy Nightly from Automated Builds

```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages
on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy
        run: |
          github-pages deploy \
            --source ./build \
            --repo ${{ github.repository }}
```

### 2. Multi-Environment Setup

```bash
# Staging
github-pages deploy --repo user/project-staging --branch gh-pages

# Production
github-pages deploy --repo user/project --branch main --domain project.com
```

## Troubleshooting

**Error: "Repository not found"**
- Verify GitHub token has `repo` scope
- Check repository name format: `username/repo-name`

**Error: "Pages not building"**
- Ensure index.html exists in root
- Check GitHub Pages is enabled in repo settings
- Verify branch is set to `gh-pages` or `main`

**Custom domain not working**
- CNAME file must be in repo root
- DNS A records should point to GitHub IPs
- Wait 5-10 minutes for DNS propagation

## Output Examples

After successful deployment:

```json
{
  "url": "https://username.github.io/repo-name",
  "customDomain": "demo.mycompany.com",
  "deployTime": "2026-02-21T05:00:00Z",
  "pages": [
    "index.html",
    "features.html",
    "contact.html"
  ],
  "template": "tech-showcase",
  "repo": "username/repo-name"
}
```

## Security Notes

- Never commit `.env` files with tokens
- Use GitHub Secrets for CI/CD deployments
- Restrict token permissions (read/write repos only)
- Enable branch protection for production sites

## Integration with Other Tools

- **N8N:** Trigger deployments from workflows
- **Vercel:** Compare with Vercel deployments
- **Netlify:** Alternative deployment target
- **Cloudflare:** Add CDN and custom domains

## Best Practices

1. **Use descriptive repo names** (`demo-ai-system` vs `test123`)
2. **Add README.md** explaining the project
3. **Include LICENSE** for open source projects
4. **Enable HTTPS** (automatic on GitHub Pages)
5. **Add analytics** for tracking visitors
6. **Optimize images** before deployment
7. **Test mobile responsiveness**

## References

- GitHub Pages Docs: https://docs.github.com/en/pages
- Managing Custom Domains: https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site
- GitHub Actions for Pages: https://github.com/actions/deploy-pages