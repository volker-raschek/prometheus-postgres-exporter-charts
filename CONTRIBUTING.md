# Contributing

I am very happy if you would like to provide a pull request 👍

The content of this file describes which requirements contributors should fulfill before submitting a pull request (PR).

1. [Valid Git commits](#valid-git-commits)

## Valid Git commits

### Commit message

The repository is subject to a strict commit message template. This states that there are several types of commits. For
example, `fix`, `chore`, `refac`, `test` or `doc`. All types are described in more detail below.

| type                | description                                                       |
| ------------------- | ----------------------------------------------------------------- |
| `feat`              | New feature.                                                      |
| `fix`               | Fixes a bug.                                                      |
| `refac`             | Refactoring production code.                                      |
| `style`             | Fixes formatting issues. No production code change.               |
| `docs`              | Adapt documentation. No production code change.                   |
| `test`              | Adds new or modifies existing tests. No production code change.   |
| `chore`             | Updating grunt tasks. Is everything which the user does not see.  |

Based on these types, commit messaged can then be created. Here are a few examples:

```text
style(README): Wrong indentation
feat(deployment): support restartPolicy
fix(my-app): Add missing volume
docs(CONTRIBUTING): Describe how to commit correctly
```

This type of commit message makes it easier for me as maintainer to keep an overview and does not cause the commits of a
pull request PR to be combined into one commit (squashing).

### Smart commits

Smart commits are excellent when it comes to tracking bugs or issues. In this repository, however, the rebasing of
commits is prohibited, which means that only merge commits are possible. This means that a smart commit message only
needs to be added to the merge commit.

This has the advantage that the maintainer can use the smart commit to find the merge commit and undo the entire history
of a merge without having to select individual commits. The following history illustrates the correct use of smart commits.

```text
* 823edbc7 Volker Raschek (G) | [Close #2] feat(deployment): support additional containers
|\
| * 321aebc3 Volker Raschek (G) | doc(README): generate README with new deployment attributes
| * 8d101dd3 Volker Raschek (G) | test(deployment): Extend unittest of additional containers
| * 6f2abd93 Volker Raschek (G) | fix(deployment): Extend deployment of additional containers
|/
* aa5ebda bob (N) | [Close #1] feat(deployment): support initContainers
```

### Commit signing

Another problem with Git is the chain of trust. Git allows the configuration of any name and e-mail address. An attacker
can impersonate any person and submit pull requests under a false identity. For as Linux Torvalds, the maintainer of the
Linux kernel.

```bash
git config --global user.name 'Linux Torvalds'
git config --global user.email 'torvalds@linux-foundation.org'
```

To avoid this, some Git repositories expect signed commits. In particular, repositories that are subject to direct
delivery to customers. For this reason, the repository is subject to a branch protection rule that only allows signed
commits. *Until* there is *no verified* and *no signed* commit, the pull request is blocked.

The following articles describes how Git can be configured to sign commits. Please keep in mind, that the e-mail
address, which is used as UID of the GPG keyring must also be defined in the profile settings of your GitHub account.
Otherwise will be marked the Git commit as *Unverified*.

1. [Signing Commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)
2. [Tell Git about your signing key](https://docs.github.com/en/authentication/managing-commit-signature-verification/telling-git-about-your-signing-key)

Inspect your Git commit via `git log`. There should be mentioned, that your commit is signed.

Furthermore, the GPG key is unique. **Don't loose your private GPG key**. Backup your private key on a safe device. For
example an external USB drive.
