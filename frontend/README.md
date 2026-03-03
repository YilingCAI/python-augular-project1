# Frontend

Angular frontend application (TypeScript + Tailwind) served by Nginx in containerized environments.

## Local setup

```bash
cd frontend
npm ci
npm start
```

Or from project root:

```bash
make frontend
```

Local URL: http://localhost:4200

## Full-stack local run

```bash
make dev
```

Expected local dependencies:

- Backend API at http://localhost:8000

## Testing and quality

```bash
npm run lint
npm run type-check
npm run test:ci
```

Coverage:

```bash
npm run test:ci -- --code-coverage
```

## Build

```bash
npm run build
```

Build output is served by Nginx in Docker/ECS runtime.

## Environment files

- `src/environments/environment.ts` (local)
- `src/environments/environment.production.ts` (production build)

These files only contain non-secret public config (for example API base URLs).

## Structure

```text
frontend/
├── src/
│   ├── app/
│   │   ├── components/
│   │   ├── services/
│   │   ├── core/
│   │   └── types/
│   └── environments/
├── angular.json
├── package.json
└── Dockerfile
```

## CI/CD notes

- `ci.yml`: lint, type-check, build
- `staging.yml` and `release.yml`: build frontend image and push to ECR
