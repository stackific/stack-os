# Stack OS docs

The Stack OS documentation site, built with [Starlight](https://starlight.astro.build). Its main section, "How it was made", records every step of the project: goal, expectations, prompt and result.

Pages live in `src/content/docs/`; images they embed live in `src/assets/`. Run everything from the repository root through [Task](https://taskfile.dev/):

| Command                  | Action                                      |
| :----------------------- | :------------------------------------------ |
| `task docs:dev`          | Starts the dev server at `localhost:4321`   |
| `task docs:build`        | Builds the site into `docs/dist/`           |
| `task docs:check`        | Type-checks the site                        |
| `task docs:astro -- ...` | Runs an Astro CLI command                   |
