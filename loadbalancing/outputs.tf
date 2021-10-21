# --- loadbalancing/outputs.tf --- 

output "lb_target_group_arn" {
  value = aws_lb_target_group.vasko_tg.arn
}

output "lb_endpoint" {
  value = aws_lb.vasko_lb.dns_name
}