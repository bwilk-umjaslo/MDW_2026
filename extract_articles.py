from pathlib import Path
import re
root = Path('content')
articles = sorted(root.rglob('*.md'))
for p in articles:
    print('FILE:', p)
    with p.open('r', encoding='utf-8') as f:
        for i, line in enumerate(f):
            if i >= 20:
                break
            print(line.rstrip('\n'))
    print('---')
