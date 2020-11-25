#!/bin/bash

# ECS config
{
    echo "ECS_CLUSTER=cluster-project-name"
} >> /etc/ecs/ecs.config

start ecs

echo "Done"
