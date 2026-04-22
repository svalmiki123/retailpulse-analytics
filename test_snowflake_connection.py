#!/usr/bin/env python3
"""
Test Snowflake Connection & Determine Correct Account Identifier Format

This script helps diagnose Snowflake authentication issues and determines
the correct format for GitHub Actions secrets.
"""

import os
import sys
from getpass import getpass

try:
    import snowflake.connector
    from snowflake.connector import DictCursor
except ImportError:
    print("❌ snowflake-connector-python not installed")
    print("Install with: pip install snowflake-connector-python")
    sys.exit(1)


def test_connection(account, user, password, role="SYSADMIN"):
    """Test Snowflake connection and return account details"""
    print(f"\n🔄 Testing connection with account='{account}', user='{user}', role='{role}'...")

    try:
        conn = snowflake.connector.connect(
            account=account,
            user=user,
            password=password,
            role=role,
            warehouse="TRANSFORM_WH",  # Will use default if doesn't exist
        )

        cursor = conn.cursor(DictCursor)

        # Get account information
        cursor.execute("""
            SELECT
                CURRENT_ORGANIZATION_NAME() as org_name,
                CURRENT_ACCOUNT_NAME() as account_name,
                CURRENT_ACCOUNT() as account_locator,
                CURRENT_REGION() as region,
                CURRENT_USER() as current_user,
                CURRENT_ROLE() as current_role,
                CURRENT_VERSION() as snowflake_version
        """)

        result = cursor.fetchone()

        cursor.close()
        conn.close()

        return True, result

    except Exception as e:
        return False, str(e)


def print_results(success, result):
    """Print connection test results"""
    if success:
        print("\n✅ CONNECTION SUCCESSFUL!\n")
        print("=" * 70)
        print("SNOWFLAKE ACCOUNT INFORMATION")
        print("=" * 70)
        print(f"Organization Name:    {result['ORG_NAME']}")
        print(f"Account Name:         {result['ACCOUNT_NAME']}")
        print(f"Account Locator:      {result['ACCOUNT_LOCATOR']}")
        print(f"Region:               {result['REGION']}")
        print(f"User:                 {result['CURRENT_USER']}")
        print(f"Role:                 {result['CURRENT_ROLE']}")
        print(f"Snowflake Version:    {result['SNOWFLAKE_VERSION']}")
        print("=" * 70)

        return result
    else:
        print(f"\n❌ CONNECTION FAILED!")
        print(f"Error: {result}")
        return None


def print_github_secrets_config(info):
    """Print recommended GitHub Secrets configuration"""
    if not info:
        return

    org_name = info['ORG_NAME']
    account_name = info['ACCOUNT_NAME']
    account_locator = info['ACCOUNT_LOCATOR']
    region = info['REGION']

    print("\n" + "=" * 70)
    print("RECOMMENDED GITHUB SECRETS CONFIGURATION")
    print("=" * 70)

    # Determine which format to use
    if org_name and account_name:
        print("\n✅ Your account uses the NEW organization-based format\n")

        # For dbt (uses 'account' parameter)
        dbt_account = f"{org_name}-{account_name}"

        print("GitHub Secrets:")
        print("-" * 70)
        print(f"SNOWFLAKE_ORGANIZATION = {org_name}")
        print(f"SNOWFLAKE_ACCOUNT      = {account_name}")
        print(f"SNOWFLAKE_USERNAME     = <your_username>")
        print(f"SNOWFLAKE_PASSWORD     = <your_password>")
        print(f"SNOWFLAKE_TF_USERNAME  = <your_terraform_username>")
        print(f"SNOWFLAKE_TF_PASSWORD  = <your_terraform_password>")

        print("\n" + "-" * 70)
        print("For dbt profiles.yml (account parameter):")
        print("-" * 70)
        print(f"account: \"{dbt_account}\"  # Format: orgname-accountname")

        print("\n" + "-" * 70)
        print("For Terraform provider:")
        print("-" * 70)
        print(f"organization_name = \"{org_name}\"")
        print(f"account_name      = \"{account_name}\"")

    else:
        print("\n✅ Your account uses the LEGACY locator-based format\n")

        # For legacy format
        legacy_account = f"{account_locator}.{region}"

        print("GitHub Secrets:")
        print("-" * 70)
        print(f"SNOWFLAKE_ACCOUNT      = {legacy_account}")
        print(f"SNOWFLAKE_USERNAME     = <your_username>")
        print(f"SNOWFLAKE_PASSWORD     = <your_password>")
        print(f"SNOWFLAKE_TF_USERNAME  = <your_terraform_username>")
        print(f"SNOWFLAKE_TF_PASSWORD  = <your_terraform_password>")

        print("\n" + "-" * 70)
        print("For dbt profiles.yml (account parameter):")
        print("-" * 70)
        print(f"account: \"{legacy_account}\"  # Format: locator.region")

    print("\n" + "=" * 70)


def main():
    print("=" * 70)
    print("SNOWFLAKE CONNECTION TESTER")
    print("=" * 70)
    print("\nThis script will help you determine the correct Snowflake")
    print("account identifier format for GitHub Actions.")
    print("\nYou can provide credentials via environment variables or input them below:")
    print("  - SNOWFLAKE_ACCOUNT (required)")
    print("  - SNOWFLAKE_USERNAME (required)")
    print("  - SNOWFLAKE_PASSWORD (required)")
    print("\n" + "=" * 70)

    # Get credentials
    account = os.getenv('SNOWFLAKE_ACCOUNT')
    user = os.getenv('SNOWFLAKE_USERNAME')
    password = os.getenv('SNOWFLAKE_PASSWORD')

    if not account:
        print("\n📝 Enter Snowflake credentials:")
        account = input("Account (e.g., 'orgname-accountname' or 'xy12345.us-west-2'): ").strip()
    else:
        print(f"\n✓ Using SNOWFLAKE_ACCOUNT from environment: {account}")

    if not user:
        user = input("Username: ").strip()
    else:
        print(f"✓ Using SNOWFLAKE_USERNAME from environment: {user}")

    if not password:
        password = getpass("Password: ")
    else:
        print("✓ Using SNOWFLAKE_PASSWORD from environment")

    if not all([account, user, password]):
        print("\n❌ All credentials are required!")
        sys.exit(1)

    # Test connection
    success, result = test_connection(account, user, password)
    info = print_results(success, result)

    if info:
        print_github_secrets_config(info)

        # Test with USERADMIN role too
        print("\n" + "=" * 70)
        print("TESTING ADDITIONAL ROLES")
        print("=" * 70)

        for role in ['USERADMIN', 'SECURITYADMIN']:
            success, result = test_connection(account, user, password, role)
            if success:
                print(f"✅ {role}: Connection successful")
            else:
                print(f"❌ {role}: {result}")

        print("\n" + "=" * 70)
        print("✅ TESTING COMPLETE")
        print("=" * 70)
        print("\nNext steps:")
        print("1. Update GitHub Secrets with the values shown above")
        print("2. Go to: https://github.com/<your-org>/<your-repo>/settings/secrets/actions")
        print("3. Update each secret with the correct value")
        print("4. Re-run the failed workflows")

    else:
        print("\n" + "=" * 70)
        print("TROUBLESHOOTING")
        print("=" * 70)
        print("\nIf connection failed, try these account formats:")
        print("\n1. Organization-based (new format):")
        print("   - Format: orgname-accountname")
        print("   - Example: myorg-myaccount")
        print("\n2. Locator-based (legacy format):")
        print("   - Format: locator.region")
        print("   - Example: xy12345.us-west-2")
        print("   - Example: xy12345.us-east-1.aws")
        print("\nYou can find your account identifier in:")
        print("  - Snowflake Web UI: Click your name → Account")
        print("  - Admin Console: Admin → Accounts")

        sys.exit(1)


if __name__ == "__main__":
    main()
