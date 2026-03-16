
**Special Case - .duo directory detected**:
The `.duo/` directory is created by duo:run and should NOT be committed.
Please add it to .gitignore:
```bash
echo '.duo*' >> .gitignore
git add .gitignore
```
