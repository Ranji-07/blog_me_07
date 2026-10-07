# Public portfolio content

`portfolio.json` is the single content source for the static portfolio build.
Edit it to change the public name, job roles, skills, timeline, projects,
contact address, and social links. It is bundled into the web release, so a
content edit requires a new web build and GitHub Pages deployment.

## Important keys

| Section | Keys you will normally edit |
| --- | --- |
| `about` | `name`, `roles`, `about_me`, `skill_categories`, `hero_background_asset` |
| `projects.projects` | `title`, `category`, `short_description`, `description`, `technologies`, `github`, `live_demo` |
| `journey.events` | `date`, `organization`, `title`, `description`, `technologies`, `highlights`, `current` |
| `contact` | `email`, `phone`, `location`, `social.github`, `social.linkedin`, `footer` |
| `blog.entries` | `title`, `path`, `status`, `url` |

Use `hero_background_asset: "assets/hero_portrait.png"` for the current hero.
To replace it, add your image to `assets/` and change this value. Keep the
value relative to `frontend/`, for example `assets/my-portrait.jpg`.

External project and social URLs must start with `https://`. The static site is
published at <https://ranji-07.github.io/blog_me_07/> after the Pages workflow
has succeeded.

Blog entries appear in the Work workspace. Leave `url` empty while an article
is planned; the UI will show its planned status rather than linking to a page
that does not exist.

## Contact form behaviour

The form creates a standard `mailto:` link to `contact.email`. The visitor's
browser or operating system chooses the configured handler, such as Gmail,
Outlook, Apple Mail, or another email app. The static site does not save a
submission or send mail by itself.
