output "caller_identity" {
  value = data.aws_caller_identity.current.account_id
}

output "issuer_arn" {
  value = data.aws_iam_session_context.current.issuer_arn
}

output "issuer_name" {
  value = data.aws_iam_session_context.current.issuer_name
}

output "session_name" {
  value = data.aws_iam_session_context.current.session_name
}

output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2.name
}