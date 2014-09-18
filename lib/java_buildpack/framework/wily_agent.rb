# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch Wily support.
    class WilyAgent < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        FileUtils.mkdir_p logs_dir

        download_tar
        @droplet.copy_resources
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        @droplet.java_opts
        .add_javaagent(@droplet.sandbox + 'Agent.jar')
        .add_system_property('com.wily.introscope.agentProfile', @droplet.sandbox + 'core/config/IntroscopeAgent.tomcat.profile')
        .add_system_property('introscope.agent.enterprisemanager.transport.tcp.host.DEFAULT', wily_host)
        .add_system_property('introscope.agent.enterprisemanager.transport.tcp.port.DEFAULT', wily_port)
        .add_system_property('introscope.agent.customProcessName', wily_domain)
        .add_system_property('introscope.autoprobe.logfile', "#{logs_dir}/AutoProbe.log")
        .add_system_property('log4j.appender.logfile.File', "#{logs_dir}/IntroscopeAgent.log")
        .add_option('-XX:-UseSplitVerifier')
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        @application.services.one_service? FILTER, 'domain'
      end

      private

      FILTER = /wily/.freeze

      private_constant :FILTER

      def application_name
        @application.details['application_name']
      end

      def wily_host
        @application.services.find_service(FILTER)['credentials']['host']
      end

      def wily_port
        @application.services.find_service(FILTER)['credentials']['port'] || '4500'
      end

      def wily_domain
        @application.services.find_service(FILTER)['credentials']['domain']
      end

      def logs_dir
        @droplet.sandbox + 'logs'
      end

    end

  end
end
