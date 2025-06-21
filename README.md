# AL-Go AppSource App Template

This template repository can be used for managing AppSource Apps for Business Central.

Please go to https://aka.ms/AL-Go to learn more.

## Branch-Based Dependency Management

This template includes pre-configured support for different dependency sources based on branches:

### How It Works

The CI/CD workflow automatically selects the appropriate dependencies based on the current branch:

- **Staging Branch**: Uses the latest builds (`latestBuild`) from staging dependencies
- **Main/Release Branches**: Uses released versions (`release`) from production dependencies

### Configuration

Dependencies are configured using AL-Go's native `ConditionalSettings` in `.github/AL-Go-Settings.json`:

```json
"ConditionalSettings": [
  {
    "branches": ["staging"],
    "settings": {
      "appDependencyProbingPaths": [
        {
          "repo": "*",
          "release_status": "latestBuild",
          "branch": "staging"
        }
      ]
    }
  },
  {
    "branches": ["main", "release/*"],
    "settings": {
      "appDependencyProbingPaths": [
        {
          "repo": "*",
          "release_status": "release"
        }
      ]
    }
  }
]
```

### Deployment Environments

The template also includes environment configurations:

- **Staging Environment**: Continuous deployment from staging branch
- **Production Environment**: Manual deployment from main branch

To use these environments, create corresponding GitHub environments in your repository settings.

## Contributing

Please read [this](https://github.com/microsoft/AL-Go/blob/main/Scenarios/Contribute.md) description on how to contribute to AL-Go for GitHub.

We do not accept Pull Requests on the template repository directly.
