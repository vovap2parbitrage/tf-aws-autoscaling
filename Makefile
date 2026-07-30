WB := $(shell tput -Txterm setab 7 && tput -Txterm setaf 0)
RESET := $(shell tput -Txterm sgr0)

.PHONY: terraform_init terraform_validate terraform_plan terraform_apply terraform_apply

terraform_init:
	@echo ""
	@echo "${WB}Terraform init${RESET}"
	@terraform init

terraform_validate: terraform_init
	@echo ""
	@echo "${WB}Terraform validate${RESET}"
	@terraform validate

terraform_plan: terraform_validate
	@echo ""
	@echo "${WB}Terraform plan${RESET}"
	@terraform plan -out=myplan.tfplan

terraform_apply: terraform_plan
	@echo ""
	@echo "${WB}Terraform apply${RESET}"
	@terraform apply myplan.tfplan

terraform: terraform_apply

.DEFAULT_GOAL := terraform