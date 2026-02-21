# Skill: HTML Pro Generator

Generate production-ready, responsive HTML pages with modern CSS frameworks, animations, and dark mode support.

## When to Use

Use this skill when you need to:
- Create landing pages from scratch
- Generate dashboards or admin panels
- Build presentation sites or portfolios
- Create HTML emails or newsletters
- Generate documentation sites
- Build interactive prototypes

## What It Does

1. Generates semantic HTML5 structure
2. Applies modern CSS (Tailwind, custom styles)
3. Adds responsive design (mobile-first)
4. Includes dark mode toggle/support
5. Adds animations and micro-interactions
6. Optimizes for performance and SEO
7. Includes accessibility features (a11y)

## Output Options

### Framework Options

| Option | CSS Framework | Best For |
|--------|---------------|----------|
| `tailwind` | Tailwind CSS (CDN) | Rapid prototyping, modern look |
| `bootstrap` | Bootstrap 5 | Traditional components, forms |
| `custom` | Vanilla CSS | Full control, lightweight |
| `bulma` | Bulma CSS | Clean, semantic HTML |

### Feature Flags

```bash
--dark-mode       # Include dark mode toggle
--animations      # Add scroll/fade animations
--seo             # Add meta tags, structured data
--analytics       # Include GA/GTM snippets
--forms           # Add form validation JS
--charts          # Include Chart.js/Plotly
--icons           # Include Font Awesome/Heroicons
```

## Usage Examples

### Basic: Single Landing Page

```bash
html-pro generate \
  --type landing \
  --title "AI Automation Services" \
  --sections hero,features,pricing,cta \
  --framework tailwind \
  --dark-mode \
  --output ./landing-page.html
```

### Advanced: Dashboard with Charts

```bash
html-pro generate \
  --type dashboard \
  --title "Analytics Dashboard" \
  --framework tailwind \
  --charts \
  --dark-mode \
  --data-source ./data.json \
  --output ./dashboard.html
```

### Using in OpenClaw

```javascript
// Generate a showcase page from project data
const html = await htmlPro.generate({
  type: 'showcase',
  title: 'Project Deliverables',
  description: 'Complete automation system for insurance quotes',
  sections: [
    { type: 'hero', title: 'Insurance Quote Comparator', subtitle: 'AI-powered automation' },
    { type: 'features', items: ['N8N Workflow', 'PDF Processing', 'Dashboard'] },
    { type: 'code-preview', files: ['workflow.json', 'processor.js'] },
    { type: 'demo', url: 'https://demo.example.com' }
  ],
  framework: 'tailwind',
  darkMode: true,
  animations: true,
  seo: true
});

// Save to file
await writeFile('./showcase.html', html);
```

## Page Types

### 1. Landing Page

Single-page site with sections:
- Hero (big headline + CTA)
- Features (grid of benefits)
- Social proof (testimonials/logos)
- Pricing (if applicable)
- FAQ
- CTA section
- Footer

### 2. Dashboard

Admin panel with:
- Sidebar navigation
- Top header with user menu
- Stats cards
- Data tables
- Charts/graphs
- Responsive mobile menu

### 3. Documentation

Docs site with:
- Sidebar navigation
- Content area with typography
- Code blocks with syntax highlighting
- Search bar (UI only)
- "On this page" navigation
- Mobile responsive

### 4. Portfolio

Personal showcase:
- Hero with photo/bio
- Projects grid
- Skills section
- Contact form
- Social links

### 5. Showcase

Project/demo display:
- Hero with project title
- Feature highlights
- Code snippets
- Live demo embed
- Download/links section

## Component Library

### Navigation

```html
<!-- Sticky header with mobile menu -->
<header class="sticky top-0 z-50 bg-white/80 backdrop-blur-md dark:bg-gray-900/80">
  <nav class="container mx-auto px-6 py-4 flex justify-between items-center">
    <a href="#" class="text-2xl font-bold">Logo</a>
    <div class="hidden md:flex space-x-6">
      <a href="#features" class="hover:text-blue-500">Features</a>
      <a href="#pricing" class="hover:text-blue-500">Pricing</a>
    </div>
    <button class="md:hidden" onclick="toggleMenu()">☰</button>
  </nav>
</header>
```

### Hero Section

```html
<section class="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-600 to-purple-700">
  <div class="text-center text-white px-6">
    <h1 class="text-5xl md:text-7xl font-bold mb-6">Headline Here</h1>
    <p class="text-xl md:text-2xl mb-8 text-white/90">Subheadline description</p>
    <div class="flex gap-4 justify-center">
      <button class="px-8 py-3 bg-white text-blue-600 rounded-full font-semibold hover:shadow-lg transition">
        Get Started
      </button>
      <button class="px-8 py-3 border-2 border-white text-white rounded-full font-semibold hover:bg-white/10 transition">
        Learn More
      </button>
    </div>
  </div>
</section>
```

### Features Grid

```html
<section id="features" class="py-20 bg-gray-50 dark:bg-gray-900">
  <div class="container mx-auto px-6">
    <h2 class="text-3xl md:text-4xl font-bold text-center mb-12 text-gray-900 dark:text-white">
      Key Features
    </h2>
    <div class="grid md:grid-cols-3 gap-8">
      <!-- Feature Card -->
      <div class="p-6 bg-white dark:bg-gray-800 rounded-2xl shadow-lg hover:shadow-xl transition">
        <div class="w-12 h-12 bg-blue-100 dark:bg-blue-900 rounded-xl flex items-center justify-center mb-4">
          ⚡
        </div>
        <h3 class="text-xl font-semibold mb-2 dark:text-white">Fast</h3>
        <p class="text-gray-600 dark:text-gray-300">Description of the feature goes here.</p>
      </div>
    </div>
  </div>
</section>
```

### Code Block with Syntax Highlighting

```html
<div class="rounded-xl overflow-hidden bg-gray-900 my-6">
  <div class="flex items-center justify-between px-4 py-2 bg-gray-800">
    <span class="text-sm text-gray-400">JavaScript</span>
    <button onclick="copyCode(this)" class="text-sm text-gray-400 hover:text-white">Copy</button>
  </div>
  <pre class="p-4 overflow-x-auto"><code class="language-javascript text-sm text-gray-300">
const greeting = "Hello World";
console.log(greeting);
  </code></pre>
</div>
```

### Dark Mode Toggle

```html
<button onclick="toggleDarkMode()" class="p-2 rounded-lg bg-gray-200 dark:bg-gray-700">
  <span class="dark:hidden">🌙</span>
  <span class="hidden dark:inline">☀️</span>
</button>

<script>
  function toggleDarkMode() {
    document.documentElement.classList.toggle('dark');
    localStorage.setItem('theme', document.documentElement.classList.contains('dark') ? 'dark' : 'light');
  }
  
  // Check saved preference
  if (localStorage.getItem('theme') === 'dark' || 
      (!localStorage.getItem('theme') && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    document.documentElement.classList.add('dark');
  }
</script>
```

## Animations Library

### Scroll Reveal

```javascript
// Intersection Observer for scroll animations
const observerOptions = {
  root: null,
  rootMargin: '0px',
  threshold: 0.1
};

const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('animate-fade-in');
    }
  });
}, observerOptions);

document.querySelectorAll('.reveal').forEach(el => observer.observe(el));
```

### Hover Effects

```css
/* Tailwind classes */
.hover-lift:hover {
  transform: translateY(-4px);
  box-shadow: 0 20px 40px rgba(0,0,0,0.1);
}

/* Smooth transitions */
.transition-all {
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}
```

## SEO Optimization

Auto-generated meta tags:

```html
<head>
  <!-- Basic Meta -->
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Page Title | Brand</title>
  <meta name="description" content="Page description for search engines">
  
  <!-- Open Graph -->
  <meta property="og:title" content="Page Title">
  <meta property="og:description" content="Description">
  <meta property="og:image" content="https://example.com/image.jpg">
  <meta property="og:url" content="https://example.com/page">
  
  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="Page Title">
  <meta name="twitter:description" content="Description">
  
  <!-- Structured Data -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "Page Title",
    "description": "Description"
  }
  </script>
</head>
```

## Integration Patterns

### With N8N

```json
{
  "name": "Generate HTML Report",
  "type": "code",
  "parameters": {
    "jsCode": "return htmlPro.generate({ type: 'dashboard', data: $input.all() });"
  }
}
```

### With GitHub Pages

```javascript
// Generate and deploy in one flow
const html = await htmlPro.generate({
  type: 'showcase',
  title: 'Project Demo',
  sections: [...]
});

await githubPages.deploy({
  source: html,
  repo: 'username/demo'
});
```

## Best Practices

1. **Mobile-first:** Always design for mobile, enhance for desktop
2. **Performance:** Keep under 100KB for critical CSS
3. **Accessibility:** Use semantic HTML, ARIA labels, alt text
4. **Dark mode:** Support `prefers-color-scheme`
5. **Load time:** Lazy load images below fold
6. **Fonts:** Use system fonts or load async
7. **Testing:** Check on real devices, not just emulator

## Common Issues

**Dark mode flash on load**
- Add script in `<head>` before any styles
- Use `class` strategy, not `media` query

**Images not responsive**
- Always use `max-w-full h-auto`
- Consider `srcset` for different sizes

**Fonts loading slowly**
- Use `font-display: swap`
- Preload critical fonts

## References

- Tailwind CSS: https://tailwindcss.com/docs
- HTML5 Semantic Elements: https://developer.mozilla.org/en-US/docs/Glossary/Semantics
- Web Accessibility: https://www.w3.org/WAI/WCAG21/quickref/