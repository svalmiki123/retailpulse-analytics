output "github_actions_user_name" {
  description = "Name of the GitHub Actions IAM user"
  value       = aws_iam_user.github_actions.name
}

output "github_actions_user_arn" {
  description = "ARN of the GitHub Actions IAM user"
  value       = aws_iam_user.github_actions.arn
}

output "access_key_id" {
  description = "Access key ID for GitHub Actions (add this to GitHub Secrets)"
  value       = aws_iam_access_key.github_actions.id
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret access key for GitHub Actions (add this to GitHub Secrets)"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}
