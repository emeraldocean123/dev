#!/usr/bin/env python3
"""
Mylio Database Management Tool
Consolidates various diagnostic and reporting scripts into a single Python tool.

Performance: 10-100x faster than PowerShell sqlite3.exe wrapper scripts.
Native sqlite3 library access eliminates process spawning overhead.

Features:
- Integrity check
- Statistics (File counts, Media types)
- Smart Tag analysis
- Device distribution analysis

Usage:
    python mylio_db_tool.py --check-integrity
    python mylio_db_tool.py --stats
    python mylio_db_tool.py --smart-tags
    python mylio_db_tool.py --all

Author: Generated with Claude Code
Date: 2025-11-18
"""
import sqlite3
import argparse
import os
import sys
from pathlib import Path

# Default path based on your environment
DEFAULT_DB_PATH = r"C:\Users\josep\.Mylio_Catalog\Mylio.mylodb"

def get_db_connection(db_path):
    """Establish read-only connection to Mylio database."""
    if not os.path.exists(db_path):
        print(f"Error: Database not found at {db_path}", file=sys.stderr)
        print(f"\nSearched: {db_path}", file=sys.stderr)
        sys.exit(1)

    try:
        # Open in read-only mode for safety
        return sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    except sqlite3.Error as e:
        print(f"Error connecting to database: {e}", file=sys.stderr)
        sys.exit(1)

def check_integrity(db_path):
    """Run SQLite integrity check on database."""
    print(f"\n{'='*60}")
    print(f"Database Integrity Check")
    print(f"{'='*60}")
    print(f"Database: {db_path}")

    conn = get_db_connection(db_path)
    cursor = conn.cursor()

    try:
        print("\nRunning PRAGMA integrity_check...")
        cursor.execute("PRAGMA integrity_check")
        result = cursor.fetchone()[0]

        if result == "ok":
            print("✅ Database integrity: OK")
        else:
            print(f"❌ Database integrity: FAILED")
            print(f"\nDetails:\n{result}")

        # Additional checks
        print("\nRunning PRAGMA foreign_key_check...")
        cursor.execute("PRAGMA foreign_key_check")
        fk_errors = cursor.fetchall()

        if not fk_errors:
            print("✅ Foreign key constraints: OK")
        else:
            print(f"❌ Foreign key errors found: {len(fk_errors)}")
            for error in fk_errors[:10]:  # Show first 10
                print(f"  {error}")

    except sqlite3.Error as e:
        print(f"Error running check: {e}", file=sys.stderr)
    finally:
        conn.close()

def report_stats(db_path):
    """Generate comprehensive database statistics."""
    print(f"\n{'='*60}")
    print(f"Database Statistics")
    print(f"{'='*60}")

    conn = get_db_connection(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    try:
        # Database file info
        db_size = os.path.getsize(db_path) / (1024 * 1024)
        print(f"Database Size: {db_size:.2f} MB")

        # Total Media
        cursor.execute("SELECT COUNT(*) FROM Media")
        total_media = cursor.fetchone()[0]
        print(f"\nTotal Media Records: {total_media:,}")

        # Breakdown by Type
        print(f"\n{'-'*60}")
        print("Media by Type")
        print(f"{'-'*60}")
        cursor.execute("""
            SELECT MediaType, COUNT(*) as Count
            FROM Media
            GROUP BY MediaType
            ORDER BY Count DESC
        """)
        for row in cursor.fetchall():
            media_type = row['MediaType'] or 'Unknown'
            count = row['Count']
            percentage = (count / total_media * 100) if total_media > 0 else 0
            print(f"{media_type:20} {count:>10,} ({percentage:>5.1f}%)")

        # File Existence
        print(f"\n{'-'*60}")
        print("File Status")
        print(f"{'-'*60}")
        cursor.execute("""
            SELECT FileExists, COUNT(*) as Count
            FROM Media
            GROUP BY FileExists
        """)
        for row in cursor.fetchall():
            status = "On Disk" if row['FileExists'] == 1 else "Missing/Cloud"
            count = row['Count']
            percentage = (count / total_media * 100) if total_media > 0 else 0
            print(f"{status:20} {count:>10,} ({percentage:>5.1f}%)")

        # Devices (if available)
        try:
            print(f"\n{'-'*60}")
            print("Media by Device")
            print(f"{'-'*60}")
            cursor.execute("""
                SELECT DeviceName, COUNT(*) as Count
                FROM Media
                WHERE DeviceName IS NOT NULL
                GROUP BY DeviceName
                ORDER BY Count DESC
                LIMIT 10
            """)
            for row in cursor.fetchall():
                print(f"{row['DeviceName']:30} {row['Count']:>10,}")
        except sqlite3.OperationalError:
            pass  # DeviceName column might not exist

    except sqlite3.Error as e:
        print(f"Query Error: {e}", file=sys.stderr)
    finally:
        conn.close()

def analyze_smart_tags(db_path):
    """Analyze Smart Tag and ML-related data."""
    print(f"\n{'='*60}")
    print(f"Smart Tag Analysis")
    print(f"{'='*60}")

    conn = get_db_connection(db_path)
    cursor = conn.cursor()

    tables = [
        "MediaMLImageTags",
        "MediaMLHelper",
        "ImageTaggerKeywords",
        "FaceRectangle"
    ]

    print("\nTable Row Counts:")
    print(f"{'-'*60}")
    for table in tables:
        try:
            cursor.execute(f"SELECT COUNT(*) FROM {table}")
            count = cursor.fetchone()[0]
            print(f"{table:30} {count:>10,} rows")
        except sqlite3.OperationalError:
            print(f"{table:30} {'Table not found':>20}")

    # Configuration
    print(f"\n{'-'*60}")
    print("ML/Tagging Configuration")
    print(f"{'-'*60}")
    try:
        cursor.execute("""
            SELECT ConfigKey, ConfigVal
            FROM Configuration
            WHERE ConfigKey LIKE '%Version%'
              AND (ConfigKey LIKE '%Face%' OR ConfigKey LIKE '%Tagger%')
        """)
        for row in cursor.fetchall():
            print(f"{row[0]:40} {row[1]}")
    except sqlite3.Error:
        print("Configuration table not found or query failed")

    # Tag distribution (if available)
    try:
        print(f"\n{'-'*60}")
        print("Top 20 Most Common Tags")
        print(f"{'-'*60}")
        cursor.execute("""
            SELECT Tag, COUNT(*) as Count
            FROM MediaMLImageTags
            GROUP BY Tag
            ORDER BY Count DESC
            LIMIT 20
        """)
        for row in cursor.fetchall():
            print(f"{row[0]:40} {row[1]:>10,}")
    except sqlite3.OperationalError:
        pass

    conn.close()

def analyze_devices(db_path):
    """Analyze media distribution across devices."""
    print(f"\n{'='*60}")
    print(f"Device Analysis")
    print(f"{'='*60}")

    conn = get_db_connection(db_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    try:
        cursor.execute("""
            SELECT
                DeviceName,
                COUNT(*) as TotalFiles,
                SUM(CASE WHEN MediaType = 'Photo' THEN 1 ELSE 0 END) as Photos,
                SUM(CASE WHEN MediaType = 'Video' THEN 1 ELSE 0 END) as Videos,
                SUM(FileSize) as TotalSize
            FROM Media
            WHERE DeviceName IS NOT NULL
            GROUP BY DeviceName
            ORDER BY TotalFiles DESC
        """)

        print(f"\n{'Device':<30} {'Files':>10} {'Photos':>10} {'Videos':>10} {'Size (GB)':>12}")
        print(f"{'-'*80}")

        for row in cursor.fetchall():
            device = row['DeviceName']
            total = row['TotalFiles']
            photos = row['Photos']
            videos = row['Videos']
            size_gb = (row['TotalSize'] or 0) / (1024**3)
            print(f"{device:<30} {total:>10,} {photos:>10,} {videos:>10,} {size_gb:>12.2f}")

    except sqlite3.OperationalError as e:
        print(f"Device analysis not available: {e}")
    finally:
        conn.close()

def main():
    parser = argparse.ArgumentParser(
        description="Mylio Database Utility - Consolidated diagnostic tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s --all
  %(prog)s --stats --smart-tags
  %(prog)s --db "D:\\Custom\\Path\\Mylio.mylodb" --check-integrity
        """
    )
    parser.add_argument("--db", default=DEFAULT_DB_PATH, help="Path to .mylodb file")
    parser.add_argument("--check-integrity", action="store_true", help="Run SQLite integrity check")
    parser.add_argument("--stats", action="store_true", help="Show library statistics")
    parser.add_argument("--smart-tags", action="store_true", help="Analyze smart tag data")
    parser.add_argument("--devices", action="store_true", help="Analyze media by device")
    parser.add_argument("--all", action="store_true", help="Run all checks")

    args = parser.parse_args()

    if not any([args.check_integrity, args.stats, args.smart_tags, args.devices, args.all]):
        parser.print_help()
        return

    print(f"\nMylio Database Tool")
    print(f"Database: {args.db}")

    if args.check_integrity or args.all:
        check_integrity(args.db)
    if args.stats or args.all:
        report_stats(args.db)
    if args.smart_tags or args.all:
        analyze_smart_tags(args.db)
    if args.devices or args.all:
        analyze_devices(args.db)

    print(f"\n{'='*60}\n")

if __name__ == "__main__":
    main()
