#!/usr/bin/env python3

import sys
import os
import re
import json
import sqlite3
import zipfile
import tempfile
import argparse
import shutil
import subprocess
import html
from datetime import datetime
from pathlib import Path

progname = os.path.basename(sys.argv[0])
version = "0.55"

# Get file modification time
script_path = os.path.realpath(__file__)
mod_time = datetime.fromtimestamp(os.path.getmtime(script_path)).strftime('%Y-%m-%d')
verstring = f"{progname} version {version} ({mod_time})"

usage = f"""Usage: {progname} [-ilf] <in_file> [<out_file>]
       {progname} -j|-J|-c [-espklf] [-m <num>] [-d <num>] <in_file> [<out_file>]
       {progname} -x [-lf] <in_file> [<out_file>]
       {progname} -h        (for help)"""

help_text = f"""
Help on {verstring}

This program exports facts (also called notes) from Anki
decks or deck collections in .apkg or .colpkg files.
There are 6 separate modes of operation:

        Info about the Anki file to show on screen
    -i  Info about the Anki file in JSON format
    -c  Extract facts as CSV files
    -j  Extract facts as compact JSON
    -J  Extract facts as verbose JSON
    -x  Dump all available data unchanged as JSON

Anki files may contain more than one deck or subdeck, and
usually contain more than one model. A "model" is a named
set of field names for the facts. When no options are used,
a numbered list of the decks and models in the Anki file are
shown. These numbers can then be used with the -d and -m
options to select the decks and models to export.

Be aware that each model can be used in more than one deck
or subdeck so selecting a single model with -m may not be
sufficient to select only one type of fact. In this case you
can also use the -d option to select the deck you want and
so avoid mixing different types of facts together. Also -p
adds the path of the subdeck to a "subdeck" field in every
fact so you can see which deck each fact came from.

Note that options -m -d -e -s -p -k described below only
work in the fact extraction modes -j -J -c.


SYNOPSIS:

    {usage.replace(progname + ' ', '    ')}


OPTIONS:

        Info mode is when there are no options. It lists the
        decks and models present in the given <in_file>.

    -i  Info mode in JSON format. Outputs a JSON version of
        the file info instead of the human readable version.

    -c  Output facts as CSV files. CSV is the best format
        for import into a spreadsheet for example. Facts for
        each model are written to separate CSV files with
        field names on the first line like this:

        "field name 1","field name 2","field name 3"
        "fact 1 value 1","fact 1 value 2","fact 1 value 3"
        "fact 2 value 1","fact 2 value 2","fact 2 value 3"
        "fact 3 value 1","fact 3 value 2","fact 3 value 3"

    -j  Output facts as a JSON object (compact style).
        The field names are written once only, and the
        fact values are written as arrays of strings.

        {{
          "model 1": {{
            "fields": ["field name 1", "field name 2", "field name 3"],
            "facts": [
              ["fact 1 value 1", "fact 1 value 2", "fact 1 value 3"],
              ["fact 2 value 1", "fact 2 value 2", "fact 2 value 3"]
            ]
          }}
        }}

    -J  Output facts as a JSON object (verbose style).
        Like -j except the field names are the keys of every
        fact object, instead of a list of fields just once.

        {{
          "model 1": [
            {{
              "field name 1": "fact 1 value 1",
              "field name 2": "fact 1 value 2"
              "field name 3": "fact 1 value 3"
            }},
            {{
              "field name 1": "fact 2 value 1",
              "field name 2": "fact 2 value 2"
              "field name 3": "fact 2 value 3"
            }}
          ]
        }}

    -s  Simplify and separate the JSON outputs for each
        model instead of a combined JSON object for all
        models keyed on model name. Useful when -m is used
        to select a single model and you just want the facts
        themselves. So -js outputs objects like this:

        {{
          "fields": ["field name 1", "field name 2", "field name 3"],
          "facts": [
            ["fact 1 value 1", "fact 1 value 2", "fact 1 value 3"],
            ["fact 2 value 1", "fact 2 value 2", "fact 2 value 3"]
          ]
        }}

        and -Js outputs an array of objects like this:

        [
          {{
            "field name 1": "fact 1 value 1",
            "field name 2": "fact 1 value 2"
            "field name 3": "fact 1 value 3"
          }},
          {{
            "field name 1": "fact 2 value 1",
            "field name 2": "fact 2 value 2"
            "field name 3": "fact 2 value 3"
          }}
        ]

    -m <num>
        Choose the model number <num> to extract instead of
        extracting all models. The <num> is a model number
        as listed by info mode. More than one <num> may be
        comma separated.

    -d <num>
        Choose the deck number <num> to extract instead of
        extracting all decks. The <num> is a deck number
        as listed by info mode. More than one <num> may be
        comma separated. All subdecks of the given deck are
        also included unless you also use the -e option.

    -e  Exact deck number. Only output facts with cards in
        the exact deck given in the -d option. So it does
        not automatically include all subdecks.

    -p  Include path (eg. deck::subdeck::subsubdeck) of the
        subdeck in a "subdeck" field. Note: If a fact is
        used by cards in more than one deck, then only the
        alphabetically first subdeck path is included.

    -k  Keep HTML tags and entities in data. By default
        HTML tags are removed and HTML entities converted.

    -f  Force overwrite of existing files. By default a
        warning is shown and files are not overwritten.

    -x  Dump JSON equivalent of all data in the Anki file
        with minimal processing. Useful for debugging.

    -l  Use 'less' pager to display output neatly formatted
        instead of saving files on disk or sending minimal
        JSON to stdout. Useful for visualising what the
        output will be before actually making files.

    -V  Display program version and exit.

    -h  Display this help and exit.


DESCRIPTION:

The <in_file> is the Anki deck or collection from which to
extract information, and <out_file> is the file in which to
place the output, or the prefix path on which to base output
filenames depending on the mode and options.

In -c CSV mode, facts from each model are saved to separate
CSV files using <out_file> as a prefix and the model name as
suffix. If no <out_file> is given then the <in_file> is used
as the prefix. If the <out_file> is - then all CSV data is
written to stdout, which is only useful if the deck and
model have been selected using -d and -m options.

Similarly, when -s is used with JSON modes -j -J then facts
from each model are saved to separate JSON files using
<out_file> as a prefix and the model name as suffix. If no
<out_file> is given then the <in_file> is used as the
prefix. If the <out_file> is - then a stream of JSON objects
is written to stdout without separating commas.

In the other modes -i -x and -j -J without -s, the output is
sent to stdout by default. If <out_file> is given, and it is
not - then output is saved to that <out_file> (possibly with
a different file extension to match the output type).

Note: From Anki version 2.1.50 onwards, the format of Anki's
saved decks changed. This program does not work with the
newer format. Fortunately, public shared decks on AnkiWeb
use the older format. When you export your own decks from
Anki you can tick the option "Support older Anki versions"
to get the older format this program needs.

Public shared Anki decks are available from:

    https://ankiweb.net/shared/decks


EXAMPLES:

To list the decks and models in an Anki deck file:

    $ {progname} mydeck.apkg

You can grep the output of the above command to quickly find
the number of a specific deck or model. Or you could display
the same information in the less pager with:

    $ {progname} -l mydeck.apkg

To display facts in JSON format neatly for viewing:

    $ {progname} -Jl mydeck.apkg

If you want to pipe the stream of JSON objects produced by
the -s option, which normally writes to a separate file for
each model, you must explicitly indicate that you want the
output to go to stdout by putting a - as the <out_file> like
this for example to pipe into jq:

    $ {progname} -Js -m1 mydeck.apkg -  | jq -s length

To extract all models as CSV files saved in a directory,
put a / on the end of the <out_file> like this:

    $ {progname} -c mydeck.apkg outdir/

To extract facts from many Anki files, use a bash for-loop:

    $ for f in *.apkg; do {progname} -js "$f" myjson/; done

____________________________________________________________
"""

# Global variables
json_info = False       # -i
csv_out = False         # -c
json_compact = False    # -j
json_verbose = False    # -J
json_dump = False       # -x
text_info = False       # if none of the above
decks = []              # -d <num>
models = []             # -m <num>
exact_deck = False      # -e
separate = False        # -s
add_subdeck = False     # -p
keep_html = False       # -k
force = False           # -f
in_file = ''            # input file
out_file = ''           # output file or prefix for files
database = ''           # current sqlite database
to_stdout = False       # whether output should go to stdout
to_less = False         # whether to display output in less
less_file = ''          # temp file holds output for less
dids = ''               # deck ids depending on -d -e
mids = ''               # model ids depending on -m
tempfiles = {}          # track temp files so exit handler can tidy them up


def warn(*args):
    """Print warning messages to stderr."""
    for msg in args:
        if sys.stderr.isatty():
            print(f'\033[33m{msg}\033[39m', file=sys.stderr)
        else:
            print(msg, file=sys.stderr)


def die(*args):
    """Print error messages and exit."""
    if args:
        first = args[0]
        rest = args[1:]
        if sys.stderr.isatty():
            print(f'\033[1;31m{first}\033[22;39m', file=sys.stderr)
        else:
            print(first, file=sys.stderr)
        for msg in rest:
            print(msg, file=sys.stderr)
    sys.exit(1)


def show_help():
    """Display help text."""
    if sys.stdout.isatty():
        # Apply color highlighting for terminal
        text = help_text
        # Bold progname
        text = re.sub(rf'\b({progname})\b', r'\033[1m\1\033[22m', text)
        # Bold options
        text = re.sub(r'(^|\W)(-\w+)', r'\1\033[1m\2\033[22m', text)
        # Cyan for <placeholders>
        text = re.sub(r'<(\w+)>', r'<\033[36m\1\033[39m>', text)
        # URLs in blue
        text = re.sub(r'(https?://[A-Za-z0-9./-]+)', r'\033[38;5;69m\1\033[39m', text)
        # Example commands
        text = re.sub(r'^( +)\$(.*)$', r'\1\033[2m$\033[22m\033[38;5;143m\2\033[39m', text, flags=re.MULTILINE)
        # Section headers
        text = re.sub(r'^([A-Z ]+:)$', r'\033[1m\1\033[22m', text, flags=re.MULTILINE)
        
        try:
            pager = subprocess.Popen(['less', '-R'], stdin=subprocess.PIPE)
            pager.communicate(input=text.rstrip().encode())
        except:
            print(text.rstrip())
    else:
        print(help_text.rstrip())


def newtemp(suffix=''):
    """Create a new temp file and track it."""
    global tempfiles
    fd, path = tempfile.mkstemp(prefix=f'{progname}.', suffix=f'.{suffix}' if suffix else '')
    os.close(fd)
    tempfiles[path] = True
    return path


def rmtemp(*files):
    """Remove temp files and stop tracking them."""
    global tempfiles
    for f in files:
        try:
            os.remove(f)
        except:
            pass
        if f in tempfiles:
            del tempfiles[f]


def exithandler():
    """Clean up temp files on exit."""
    for f in list(tempfiles.keys()):
        try:
            os.remove(f)
        except:
            pass


import atexit
atexit.register(exithandler)


def send_out(filetype, model='', data=''):
    """Send output to appropriate destination."""
    global out_file, to_less, to_stdout, separate, force
    
    file_path = out_file
    
    if to_less and filetype == 'json':
        # Pretty print JSON with colors for less
        try:
            obj = json.loads(data) if isinstance(data, str) else data
            output = json.dumps(obj, indent=2, ensure_ascii=False)
            print(output)
        except:
            print(data)
    elif to_stdout or to_less:
        print(data, end='')
    else:
        if separate:
            file_path += f" @ {model}"
        file_path += f".{filetype}"
        
        if not force and os.path.exists(file_path):
            warn(f"Skipping existing file {file_path}")
        else:
            # Create directory if needed
            dir_path = os.path.dirname(file_path)
            if dir_path:
                os.makedirs(dir_path, exist_ok=True)
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(data)


def get_info():
    """Get deck and model info from database."""
    global database
    
    conn = sqlite3.connect(database)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Get decks and models from col table
    cursor.execute("SELECT decks, models FROM col")
    row = cursor.fetchone()
    decks_json = json.loads(row['decks'])
    models_json = json.loads(row['models'])
    
    # Get card counts per deck and models used
    cursor.execute("""
        SELECT c.did, COUNT(*) as cards, GROUP_CONCAT(DISTINCT n.mid) as models
        FROM cards c JOIN notes n ON c.nid=n.id
        GROUP BY c.did
    """)
    deck_stats = {str(r['did']): {'cards': r['cards'], 'models': set(r['models'].split(',')) if r['models'] else set()} 
                  for r in cursor.fetchall()}
    
    # Get fact counts per model
    cursor.execute("""
        SELECT n.mid, COUNT(DISTINCT n.id) as facts, COUNT(DISTINCT c.did) as decks
        FROM cards c JOIN notes n ON c.nid=n.id
        GROUP BY mid
    """)
    model_stats = {str(r['mid']): {'facts': r['facts'], 'decks': r['decks']} for r in cursor.fetchall()}
    
    conn.close()
    
    # Process decks
    deck_list = []
    for did, deck in decks_json.items():
        stats = deck_stats.get(did, {'cards': 0, 'models': set()})
        deck_list.append({
            'name': deck['name'],
            'cards': stats['cards'],
            'models': stats['models'],
            'did': int(did)
        })
    deck_list.sort(key=lambda x: x['name'])
    
    # Add numbering and calculate totals
    for i, deck in enumerate(deck_list):
        deck['num'] = i + 1
    
    # Calculate totals including subdecks
    for deck in deck_list:
        prefix = deck['name'] + '::'
        totcards = deck['cards']
        totmodels = set(deck['models'])
        for other in deck_list:
            if other['name'].startswith(prefix):
                totcards += other['cards']
                totmodels.update(other['models'])
        deck['totcards'] = totcards
        deck['totmodels'] = len(totmodels)
        deck['models'] = len(deck['models'])
    
    # Process models
    model_list = []
    for mid, model in models_json.items():
        stats = model_stats.get(mid, {'facts': 0, 'decks': 0})
        model_list.append({
            'name': model['name'],
            'facts': stats['facts'],
            'decks': stats['decks'],
            'fields': [f['name'] for f in model['flds']],
            'mid': int(mid)
        })
    model_list.sort(key=lambda x: x['name'])
    
    # Add numbering
    for i, model in enumerate(model_list):
        model['num'] = i + 1
    
    return {'decks': deck_list, 'models': model_list}


def do_json_info():
    """Output info in JSON format."""
    info = get_info()
    # Remove did and mid from output
    for deck in info['decks']:
        del deck['did']
    for model in info['models']:
        del model['mid']
    
    send_out('json', '', json.dumps(info, ensure_ascii=False, separators=(',', ':')))


def do_text_info():
    """Output info in human-readable text format."""
    info = get_info()
    
    try:
        cols = shutil.get_terminal_size().columns
    except:
        cols = 80
    
    lines = ['', 'DECKS:']
    
    if info['decks']:
        sz = len(str(info['decks'][-1]['num']))
        for deck in info['decks']:
            lines.append('')
            lines.append(f"{deck['num']:>{sz}}. {deck['name']}")
            lines.append(f"{'':{sz}}  cards: {deck['cards']}, models: {deck['models']}")
            if deck['cards'] != deck['totcards']:
                lines.append(f"{'':{sz}}  cards: {deck['totcards']}, models: {deck['totmodels']}    <--- total including subdecks")
    
    lines.extend(['', 'MODELS:'])
    
    if info['models']:
        sz = len(str(info['models'][-1]['num']))
        width = cols - sz - 10
        indent = ' ' * (sz + 10)
        
        for model in info['models']:
            lines.append('')
            lines.append(f"{model['num']:>{sz}}. {model['name']}")
            lines.append(f"{'':{sz}}  facts: {model['facts']}, decks: {model['decks']}")
            
            # Format fields with wrapping
            fields_str = ', '.join(model['fields'])
            if len(fields_str) <= width:
                lines.append(f"{'':{sz}}  fields: {fields_str}")
            else:
                # Wrap fields
                wrapped = []
                current_line = ''
                for field in model['fields']:
                    if not current_line:
                        current_line = field
                    elif len(current_line) + len(field) + 2 <= width:
                        current_line += ', ' + field
                    else:
                        wrapped.append(current_line)
                        current_line = field
                if current_line:
                    wrapped.append(current_line)
                
                if wrapped:
                    lines.append(f"{'':{sz}}  fields: {wrapped[0]}")
                    for w in wrapped[1:]:
                        lines.append(f"{indent}{w}")
    
    lines.append('')
    send_out('txt', '', '\n'.join(lines))


def count_decks():
    """Count number of decks."""
    global database
    conn = sqlite3.connect(database)
    cursor = conn.cursor()
    cursor.execute("SELECT decks FROM col")
    decks_json = json.loads(cursor.fetchone()[0])
    conn.close()
    return len(decks_json)


def count_models():
    """Count number of models."""
    global database
    conn = sqlite3.connect(database)
    cursor = conn.cursor()
    cursor.execute("SELECT models FROM col")
    models_json = json.loads(cursor.fetchone()[0])
    conn.close()
    return len(models_json)


def get_dids():
    """Get deck IDs for selected deck numbers."""
    global database, decks, exact_deck
    
    if not decks:
        return ''
    
    conn = sqlite3.connect(database)
    cursor = conn.cursor()
    cursor.execute("SELECT decks FROM col")
    decks_json = json.loads(cursor.fetchone()[0])
    conn.close()
    
    # Build deck list sorted by name
    deck_list = []
    for did, deck in decks_json.items():
        deck_list.append({'name': deck['name'], 'did': did})
    deck_list.sort(key=lambda x: x['name'])
    
    # Add numbering
    for i, deck in enumerate(deck_list):
        deck['num'] = i + 1
    
    # Get selected deck IDs
    selected_nums = set(decks)
    selected_dids = set()
    
    for deck in deck_list:
        if deck['num'] in selected_nums:
            selected_dids.add(deck['did'])
            if not exact_deck:
                # Include subdecks
                prefix = deck['name'] + '::'
                for other in deck_list:
                    if other['name'].startswith(prefix):
                        selected_dids.add(other['did'])
    
    return ','.join(selected_dids)


def get_mids():
    """Get model IDs for selected model numbers."""
    global database, models
    
    if not models:
        return ''
    
    conn = sqlite3.connect(database)
    cursor = conn.cursor()
    cursor.execute("SELECT models FROM col")
    models_json = json.loads(cursor.fetchone()[0])
    conn.close()
    
    # Build model list sorted by name
    model_list = []
    for mid, model in models_json.items():
        model_list.append({'name': model['name'], 'mid': mid})
    model_list.sort(key=lambda x: x['name'])
    
    # Add numbering
    for i, model in enumerate(model_list):
        model['num'] = i + 1
    
    # Get selected model IDs
    selected_nums = set(models)
    selected_mids = []
    
    for model in model_list:
        if model['num'] in selected_nums:
            selected_mids.append(model['mid'])
    
    return ','.join(selected_mids)


def process_html(text, keep_html_flag):
    """Process HTML tags and entities in text."""
    if keep_html_flag:
        return text
    
    # Remove style tags and content
    text = re.sub(r'<style\b[^>]*>[^<]*</style>', '', text, flags=re.IGNORECASE)
    
    # Convert <br> to newlines
    text = re.sub(r'<br\b[^>]*>', '\n', text, flags=re.IGNORECASE)
    
    # Convert <li> to bullet points
    def li_replace(m):
        c = m.group(1) if m.group(1) else ''
        if c in ('', '\n', '\x1f'):
            return c + '• '
        else:
            return c + '\n• '
    text = re.sub(r'(^|.)<li\b[^>]*>', li_replace, text, flags=re.IGNORECASE)
    
    # Convert <img> to [image:src]
    text = re.sub(r'<img\b[^>]*\bsrc=["\']([^"\']*)["\'][^>]*>', r'[image:\1]', text, flags=re.IGNORECASE)
    
    # Remove all other HTML tags
    text = re.sub(r'<[^>]*>', '', text)
    
    # Convert HTML entities
    text = html.unescape(text)
    
    return text


def get_facts():
    """Get facts from database."""
    global database, dids, mids, keep_html, add_subdeck
    
    conn = sqlite3.connect(database)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Get decks and models
    cursor.execute("SELECT decks, models FROM col")
    row = cursor.fetchone()
    decks_json = json.loads(row['decks'])
    models_json = json.loads(row['models'])
    
    # Build deck id to name mapping
    deck_names = {did: deck['name'] for did, deck in decks_json.items()}
    
    # Build model id to info mapping
    model_info = {}
    for mid, model in models_json.items():
        model_info[mid] = {
            'name': model['name'],
            'fields': [f['name'] for f in model['flds']]
        }
    
    # Build SQL query
    sql = """
        SELECT n.mid, n.flds, GROUP_CONCAT(c.did) as dids
        FROM cards c JOIN notes n ON c.nid=n.id
    """
    
    conditions = []
    if dids:
        conditions.append(f"c.did IN ({dids})")
    if mids:
        conditions.append(f"n.mid IN ({mids})")
    
    if conditions:
        sql += " WHERE " + " AND ".join(conditions)
    
    sql += " GROUP BY n.id ORDER BY n.sfld"
    
    cursor.execute(sql)
    notes = cursor.fetchall()
    conn.close()
    
    # Process notes into facts by model
    result = {}
    for note in notes:
        mid = str(note['mid'])
        if mid not in model_info:
            continue
            
        model_name = model_info[mid]['name']
        fields = model_info[mid]['fields']
        
        # Parse field values
        flds = note['flds'].split('\x1f')
        flds = [process_html(f, keep_html) for f in flds]
        
        # Get deck IDs for subdeck field
        note_dids = note['dids'].split(',') if note['dids'] else []
        
        # Initialize model entry if needed
        if model_name not in result:
            result[model_name] = {
                'fields': (['subdeck'] if add_subdeck else []) + fields,
                'facts': []
            }
        
        # Build fact
        fact = []
        if add_subdeck:
            # Get alphabetically first subdeck
            subdeck_names = sorted([deck_names.get(did, '') for did in note_dids])
            fact.append(subdeck_names[0] if subdeck_names else '')
        fact.extend(flds)
        
        result[model_name]['facts'].append(fact)
    
    return result


def do_csv_out():
    """Output facts as CSV files."""
    import csv
    import io
    
    facts = get_facts()
    
    for model_name, data in facts.items():
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(data['fields'])
        for fact in data['facts']:
            writer.writerow(fact)
        
        csv_data = output.getvalue()
        if to_stdout:
            csv_data += '\n'
        send_out('csv', model_name, csv_data)


def do_json_compact():
    """Output facts as compact JSON."""
    facts = get_facts()
    
    if separate:
        for model_name, data in facts.items():
            send_out('json', model_name, json.dumps(data, ensure_ascii=False, separators=(',', ':')))
    else:
        send_out('json', '', json.dumps(facts, ensure_ascii=False, separators=(',', ':')))


def do_json_verbose():
    """Output facts as verbose JSON (fields as keys)."""
    facts = get_facts()
    
    # Convert to verbose format
    verbose = {}
    for model_name, data in facts.items():
        fields = data['fields']
        verbose_facts = []
        for fact in data['facts']:
            verbose_fact = {}
            for i, field in enumerate(fields):
                if i < len(fact):
                    verbose_fact[field] = fact[i]
            verbose_facts.append(verbose_fact)
        verbose[model_name] = verbose_facts
    
    if separate:
        for model_name, data in verbose.items():
            send_out('json', model_name, json.dumps(data, ensure_ascii=False, separators=(',', ':')))
    else:
        send_out('json', '', json.dumps(verbose, ensure_ascii=False, separators=(',', ':')))


def do_json_dump():
    """Dump all data as JSON."""
    global database, in_file
    
    # Extract media file
    with zipfile.ZipFile(in_file, 'r') as zf:
        try:
            media_data = json.loads(zf.read('media').decode('utf-8'))
        except:
            media_data = {}
    
    conn = sqlite3.connect(database)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Get col data
    cursor.execute("SELECT * FROM col")
    col = dict(cursor.fetchone())
    del col['id']
    col['conf'] = json.loads(col['conf']) if col['conf'] else {}
    col['models'] = json.loads(col['models']) if col['models'] else {}
    col['decks'] = json.loads(col['decks']) if col['decks'] else {}
    col['dconf'] = json.loads(col['dconf']) if col['dconf'] else {}
    col['tags'] = json.loads(col['tags']) if col['tags'] else {}
    
    # Get notes
    cursor.execute("SELECT * FROM notes")
    notes = []
    for row in cursor.fetchall():
        note = dict(row)
        if note.get('data') and len(note['data']) > 0:
            try:
                note['data'] = json.loads(note['data'])
            except:
                pass
        note['flds'] = note['flds'].split('\x1f') if note['flds'] else []
        notes.append(note)
    
    # Get cards
    cursor.execute("SELECT * FROM cards")
    cards = []
    for row in cursor.fetchall():
        card = dict(row)
        if card.get('data') and len(card['data']) > 0:
            try:
                card['data'] = json.loads(card['data'])
            except:
                pass
        cards.append(card)
    
    # Get revlog
    cursor.execute("SELECT * FROM revlog")
    revlog = [dict(row) for row in cursor.fetchall()]
    
    # Get graves
    cursor.execute("SELECT * FROM graves")
    graves = [dict(row) for row in cursor.fetchall()]
    
    conn.close()
    
    result = {
        'col': col,
        'notes': notes,
        'cards': cards,
        'revlog': revlog,
        'graves': graves,
        'media': media_data
    }
    
    send_out('json', '', json.dumps(result, ensure_ascii=False, separators=(',', ':')))


def parse_num_list(value):
    """Parse comma-separated list of positive integers."""
    if not value:
        return []
    result = []
    for part in value.split(','):
        part = part.strip()
        if not part.isdigit() or int(part) < 1:
            die(f"Invalid number: {part}", usage)
        result.append(int(part))
    return result


def main():
    global json_info, csv_out, json_compact, json_verbose, json_dump, text_info
    global decks, models, exact_deck, separate, add_subdeck, keep_html, force
    global in_file, out_file, database, to_stdout, to_less, less_file, dids, mids
    
    # Parse arguments manually to match bash getopts behavior
    args = sys.argv[1:]
    i = 0
    positional = []
    
    while i < len(args):
        arg = args[i]
        
        if arg == '--':
            positional.extend(args[i+1:])
            break
        elif arg == '-V':
            print(verstring)
            sys.exit(0)
        elif arg == '-h':
            show_help()
            sys.exit(0)
        elif arg.startswith('-') and len(arg) > 1 and arg[1] != '-':
            # Handle bundled options like -Jl
            j = 1
            while j < len(arg):
                opt = arg[j]
                if opt == 'i':
                    json_info = True
                elif opt == 'c':
                    csv_out = True
                elif opt == 'j':
                    json_compact = True
                elif opt == 'J':
                    json_verbose = True
                elif opt == 'e':
                    exact_deck = True
                elif opt == 's':
                    separate = True
                elif opt == 'p':
                    add_subdeck = True
                elif opt == 'k':
                    keep_html = True
                elif opt == 'f':
                    force = True
                elif opt == 'l':
                    to_less = True
                elif opt == 'x':
                    json_dump = True
                elif opt == 'm':
                    # -m requires a value
                    if j + 1 < len(arg):
                        val = arg[j+1:]
                    elif i + 1 < len(args):
                        i += 1
                        val = args[i]
                    else:
                        die(f"Option -m requires a value", usage)
                    models.extend(parse_num_list(val))
                    break
                elif opt == 'd':
                    # -d requires a value
                    if j + 1 < len(arg):
                        val = arg[j+1:]
                    elif i + 1 < len(args):
                        i += 1
                        val = args[i]
                    else:
                        die(f"Option -d requires a value", usage)
                    decks.extend(parse_num_list(val))
                    break
                elif opt == 'V':
                    print(verstring)
                    sys.exit(0)
                elif opt == 'h':
                    show_help()
                    sys.exit(0)
                else:
                    die(f"Unknown option -{opt}", usage)
                j += 1
        else:
            positional.append(arg)
        i += 1
    
    if len(positional) > 2:
        die("Too many arguments", usage)
    
    in_file = positional[0] if len(positional) > 0 else ''
    out_file = positional[1] if len(positional) > 1 else ''
    
    # Sanity checks
    # Check mode options
    mode_count = sum([json_info, csv_out, json_compact, json_verbose, json_dump])
    text_info = mode_count == 0
    if mode_count > 1:
        die("Cannot use more than one of the mode options -i -c -j -J -x at the same time", usage)
    
    # Check export options
    if (models or decks or exact_deck or separate or add_subdeck or keep_html) and \
       not (csv_out or json_compact or json_verbose):
        die("Cannot use any of -e -s -p -k -m -d unless exporting facts in one of the -j -J -c modes", usage)
    
    # Check input file
    if not in_file:
        die("Input filename required", usage)
    if not (in_file.endswith('.apkg') or in_file.endswith('.colpkg')):
        die("Input file not a *.apkg or *.colpkg file")
    if not os.path.isfile(in_file):
        die(f"Cannot find file: {in_file}")
    if not os.access(in_file, os.R_OK):
        die(f"Cannot read file: {in_file}")
    
    # Check if it's a zip file
    if not zipfile.is_zipfile(in_file):
        die(f"Input file is not zipped: {in_file}")
    
    # Check if it's an Anki file
    with zipfile.ZipFile(in_file, 'r') as zf:
        namelist = zf.namelist()
        if not any('collection.anki' in n for n in namelist):
            die(f"Input file is not an Anki deck: {in_file}")
        if 'collection.anki21' not in namelist:
            die(f"Unsupported Anki deck format: {in_file}")
    
    # CSV mode must always write separate outputs
    if csv_out:
        separate = True
    
    # Find output location
    if len(positional) == 1 and separate:
        out_file = re.sub(r'\.(apkg|colpkg)$', '', in_file, flags=re.IGNORECASE)
    elif len(positional) == 1 or out_file == '-':
        to_stdout = True
    elif not out_file:
        out_file = os.getcwd()
    
    if not to_stdout:
        if out_file.endswith('/') or os.path.isdir(out_file):
            out_file = out_file.rstrip('/')
            leafname = re.sub(r'\.(apkg|colpkg)$', '', os.path.basename(in_file), flags=re.IGNORECASE)
            out_file = os.path.join(out_file, leafname)
        else:
            out_file = re.sub(r'\.(csv|json)$', '', out_file, flags=re.IGNORECASE)
    
    # Extract database
    database = newtemp('sqlite')
    with zipfile.ZipFile(in_file, 'r') as zf:
        with open(database, 'wb') as f:
            f.write(zf.read('collection.anki21'))
    
    # Option -l redirects stdout to less
    less_output = []
    original_stdout = sys.stdout
    
    if to_less:
        if sys.stdout.isatty():
            less_file = newtemp('less')
            sys.stdout = open(less_file, 'w', encoding='utf-8')
        else:
            to_less = False
    
    # Get the set of deck ids and model ids if specified
    if decks:
        decks = sorted(set(decks))
        max_deck = max(decks)
        num_decks = count_decks()
        if max_deck > num_decks:
            die(f"There are only {num_decks} decks, so -d {max_deck} is out of range")
        dids = get_dids()
    
    if models:
        models = sorted(set(models))
        max_mod = max(models)
        num_mods = count_models()
        if max_mod > num_mods:
            die(f"There are only {num_mods} models, so -m {max_mod} is out of range")
        mids = get_mids()
    
    # Mode dispatch
    if text_info:
        do_text_info()
    elif json_info:
        do_json_info()
    elif csv_out:
        do_csv_out()
    elif json_compact:
        do_json_compact()
    elif json_verbose:
        do_json_verbose()
    elif json_dump:
        do_json_dump()
    else:
        die("Unknown mode (missing implementation, or a bug)")
    
    # Tidy up database temp file
    rmtemp(database)
    
    if to_less:
        # Restore stdout, run less, tidy temp file
        sys.stdout.close()
        sys.stdout = original_stdout
        try:
            subprocess.run(['less', '-R', less_file])
        except:
            with open(less_file, 'r') as f:
                print(f.read())
        rmtemp(less_file)


if __name__ == '__main__':
    main()

