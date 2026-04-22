#!/usr/bin/env python3
"""Parse Snowflake account identifier and show GitHub Secrets configuration"""

import os
import sys

account = os.getenv('SNOWFLAKE_ACCOUNT', '')

if not account:
    print("❌ SNOWFLAKE_ACCOUNT environment variable not set")
    sys.exit(1)

print("=" * 70)
print("SNOWFLAKE ACCOUNT IDENTIFIER ANALYSIS")
print("=" * 70)
print(f"\nFound SNOWFLAKE_ACCOUNT = {account}")

# Determine format
if '-' in account:
    # New organization-based format: orgname-accountname
    parts = account.split('-', 1)
    org_name = parts[0]
    account_name = parts[1]

    print("\n✅ Format: NEW organization-based (orgname-accountname)")
    print(f"   Organization: {org_name}")
    print(f"   Account:      {account_name}")

    print("\n" + "=" * 70)
    print("RECOMMENDED GITHUB SECRETS CONFIGURATION")
    print("=" * 70)
    print(f"""
For GitHub Actions Secrets:
--------------------------------------------------
SNOWFLAKE_ORGANIZATION = {org_name}
SNOWFLAKE_ACCOUNT      = {account_name}

For dbt (in workflows, this is already correct):
--------------------------------------------------
The dbt profile should use: account = "{account}"

For Terraform variables (in terraform_ci.yml):
--------------------------------------------------
TF_VAR_snowflake_organization = {org_name}
TF_VAR_snowflake_account_name = {account_name}
""")

elif '.' in account:
    # Legacy locator-based format: locator.region
    parts = account.split('.', 1)
    locator = parts[0]
    region = parts[1]

    print("\n✅ Format: LEGACY locator-based (locator.region)")
    print(f"   Locator: {locator}")
    print(f"   Region:  {region}")

    print("\n" + "=" * 70)
    print("RECOMMENDED GITHUB SECRETS CONFIGURATION")
    print("=" * 70)
    print(f"""
For GitHub Actions Secrets:
--------------------------------------------------
SNOWFLAKE_ACCOUNT = {account}

For dbt (in workflows):
--------------------------------------------------
The dbt profile should use: account = "{account}"
""")

else:
    print("\n⚠️  Format: Unknown - may be just account locator")
    print(f"   Value: {account}")

print("=" * 70)
print("CURRENT ISSUE IN YOUR WORKFLOWS")
print("=" * 70)
print("""
The problem is that GitHub Secrets currently have:
  SNOWFLAKE_ACCOUNT = KRB95438 (just account name)

But it should be:
  SNOWFLAKE_ORGANIZATION = BSGWGYG
  SNOWFLAKE_ACCOUNT      = KRB95438

AND in dbt_ci.yml, the profiles.yml generation uses:
  account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"

This needs the FULL identifier (BSGWGYG-KRB95438), but the secret
only has the account name (KRB95438), causing the 404 error.
""")

print("=" * 70)
print("TO FIX")
print("=" * 70)
print(f"""
Run these commands to update GitHub Secrets:

gh secret set SNOWFLAKE_ORGANIZATION --body "{org_name}"
gh secret set SNOWFLAKE_ACCOUNT --body "{account_name}"

OR set SNOWFLAKE_ACCOUNT to the full identifier for dbt:

gh secret set SNOWFLAKE_ACCOUNT --body "{account}"

Note: If you use the full identifier, Terraform workflow may fail
because it expects just the account name in TF_VAR_snowflake_account_name.

RECOMMENDED SOLUTION: Update dbt_ci.yml to construct the full identifier.
""")
