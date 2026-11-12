import re,glob,sys,os
# Usage: check_gd.py [root]   (default: the project's scripts/ folder)
root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'scripts')
root = os.path.normpath(root)
if not os.path.isdir(root):
    print('check_gd: not a directory:', root)
    sys.exit(2)
files=glob.glob(root+'/**/*.gd',recursive=True)
funcs={}
for name,f in [('UI','ui.gd'),('DB','db.gd'),('Store','store.gd'),('Sound','sound.gd'),('Cfg','cfg.gd')]:
    s=open(os.path.join(root,f)).read()
    names=set(re.findall(r'^(?:static )?func (\w+)',s,re.M))|set(re.findall(r'^(?:var|const) (\w+)',s,re.M))|set(re.findall(r'^signal (\w+)',s,re.M))
    funcs[name]=names
errs=0
def strip_strings(l):
    l=re.sub(r'"(\\.|[^"\\])*"','""',l)
    l=re.sub(r"'(\\.|[^'\\])*'","''",l)
    return l.split('#')[0]
for f in sorted(files):
    lines=open(f).read().split('\n')
    depth=0; prev_indent=0; prev_colon=False
    for i,raw in enumerate(lines,1):
        if raw.strip()=='' : continue
        if raw.startswith(' '):
            print(f,i,'space indent'); errs+=1
        l=strip_strings(raw)
        ind=len(raw)-len(raw.lstrip('\t'))
        if depth==0:
            stripped=l.strip()
            if stripped=='' : continue
            if ind>prev_indent and not prev_colon:
                print(f,i,'unexpected indent:',raw.strip()[:60]); errs+=1
            if prev_colon and ind<=prev_indent and not stripped.startswith(('#',)):
                print(f,i,'expected indent after colon:',raw.strip()[:60]); errs+=1
            # a line opening an inline lambda (`...connect(func():`) continues to a
            # `)`-terminated closing line, so it must not arm the indent check
            prev_colon=(stripped.endswith(':') or bool(re.search(r':\s*$',stripped))) and 'func(' not in stripped
            prev_indent=ind
        depth+=l.count('(')+l.count('[')+l.count('{')-l.count(')')-l.count(']')-l.count('}')
        if depth<0: print(f,i,'neg depth'); errs+=1; depth=0
        for m in re.finditer(r'\b(UI|DB|Store|Sound|Cfg)\.(\w+)',l):
            if m.group(2) not in funcs[m.group(1)]:
                print(f,i,'unknown',m.group(0)); errs+=1
    if depth!=0: print(f,'unbalanced at EOF',depth); errs+=1
print('errors',errs, 'files',len(files))
sys.exit(1 if errs else 0)
