
**Special Case - .humanize directory detected**:
The `.humanize/` directory is created by duo:run and should NOT be committed.
Please add it to .gitignore:
```bash
echo '.humanize*' >> .gitignore
git add .gitignore
```
