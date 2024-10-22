# telecommunication-network
# Network Gateway Project

This project implements a home network gateway with basic functionalities to control and manage network access for users. It is designed to provide a secure and restricted environment with features that limit access to registered users only, and includes mechanisms for traffic accounting and DNS resolution.

## Features

- **Home Gateway Device**: Acts as a perimeter between the home network and the telecommunication network.
  - The device can be a real home gateway device like a FritzBox or Speedport, but it isn't required.
  
- **Broadband Network Gateway (BNG)**: Manages traffic and routing for user access.

- **Access Control**: Only registered users are allowed to access the network services.

- **Traffic Accounting**: Basic functionality to track and account for each user's traffic.

- **User Traffic Separation**: Clear and enforced separation of traffic between different users for better security and management.

- **Local DNS Name Resolution**: Enables DNS name resolution within the local network for ease of use and management.

## Restrictions

- **Single IPv4 Address per Customer**: Each home is assigned only one public IPv4 address.

- **IPv6 Prefix**: A full /56 IPv6 prefix is assigned to each home network.

## Setup Instructions

1. Install and configure the home gateway device (such as a FritzBox or Speedport).
2. Set up the Broadband Network Gateway (BNG) to manage traffic routing.
3. Create user accounts and register them to control network access.
4. Implement traffic accounting mechanisms to track user data usage.
5. Configure local DNS name resolution for ease of network access.
6. Test the system by subscribing a user (e.g., your lecturer) and allow them to gain access to the network and use its services.

## Goal

The overall goal of this project is to establish a network environment where users can subscribe to the network, gain access to services, and have their traffic tracked while maintaining secure separation and name resolution capabilities.


