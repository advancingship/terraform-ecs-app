package test

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "time"
    "os"
    "fmt"
    "github.com/aws/aws-sdk-go/aws"
    "github.com/aws/aws-sdk-go/aws/credentials"
    terratest_aws "github.com/gruntwork-io/terratest/modules/aws"
    "github.com/gruntwork-io/terratest/modules/terraform"
)

// occasionally a packer build may fail due to network outage or EC2 issue
// here we specify those known common errors and retry builds if caught

var DefaultRetryablePackerErrors = map[string]string{
    "Script disconnected unexpectedly": "disconnected sometimes due to network outage",
    "can not open /var/lib/apt/lists/archive.ubuntu.com_ubuntu_dists_xenial_InRelease": "apt-get sometimes fails to update cache on xenial",
}

const DefaultTimeBetweenPackerRetries = 15 * time.Second
const DefaultMaxPackerRetries = 3

const awsRegion = "us-east-1"
var projectName = os.Getenv("TF_VAR_PROJECT_1_NAME")
var clusterName = fmt.Sprintf("cluster-%s", projectName)
var serviceName = fmt.Sprintf("service-%s", projectName)
const expectedBody = "save to reload"

var awsCredentials = credentials.NewCredentials(new(credentials.SharedCredentialsProvider))


//uppercase main test

func TestTerraformAwsEcs(t *testing.T) {
    t.Parallel()

    terraformOptions := &terraform.Options{
        // The path to where our Terraform code is located
	TerraformDir: "../prod/services/front-end",

	// Environment variables to set when running Terraform
	EnvVars: map[string]string{
	    "TF_VAR_PROJECT_1_NAME": projectName,	
	    "TF_VAR_PROJECT_1_AWS_REGION_1": awsRegion,
	},
    }

    // At the end of the test, run `terraform destroy` to clean up any created resources
    defer terraform.Destroy(t, terraformOptions)

    // This will run `terraform init` and `terraform apply` and fail the test on error
    terraform.InitAndApply(t, terraformOptions)

    // Run `terraform output` to get the value of an output variable

    vpcID := terraform.Output(t, terraformOptions, "VPCID")
    checkVPC(t, vpcID, awsRegion)

    checkCluster(t, clusterName, awsRegion)
    
    checkService(t, clusterName, serviceName, awsRegion)

    taskDefinitionARN := terraform.Output(t, terraformOptions, "task_definition")
    checkTaskDefinition(t, taskDefinitionARN, awsRegion)
}


//lowercase subroutines of main test

func checkVPC(t *testing.T, vpcID string, awsRegion string) {

    vpc := terratest_aws.GetVpcById(t, vpcID, awsRegion)

    assert.NotEmpty(t, vpc)
}


func checkCluster(t *testing.T, clusterName string, awsRegion string) {

    cluster := terratest_aws.GetEcsCluster(t, awsRegion, clusterName)

    assert.Equal(t, int64(1), aws.Int64Value(cluster.ActiveServicesCount))

}

func checkService(t *testing.T, clusterName string, serviceName string, awsRegion string) {

    service := terratest_aws.GetEcsService(t, awsRegion, clusterName, serviceName)

    assert.Equal(t, int64(1), aws.Int64Value(service.DesiredCount))

    assert.Equal(t, "EC2", aws.StringValue(service.LaunchType))    
}


func checkTaskDefinition(t *testing.T, taskDefinitionARN string, awsRegion string) {

    task := terratest_aws.GetEcsTaskDefinition(t, awsRegion, taskDefinitionARN)

    assert.Equal(t, "512", aws.StringValue(task.Memory))

    assert.Equal(t, "bridge", aws.StringValue(task.NetworkMode))
}