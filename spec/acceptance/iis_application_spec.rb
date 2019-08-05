require 'spec_helper_acceptance'

describe 'iis_application' do
  before(:all) do
    # Remove 'Default Web Site' to start from a clean slate
    remove_all_sites
  end

  context 'when creating an application' do
    context 'with normal parameters' do
      site_name = SecureRandom.hex(10).to_s
      app_name = SecureRandom.hex(10).to_s
      before(:all) do
        create_path('C:\inetpub\basic')
      end

      describe 'applies the manifest twice' do
        manifest = <<-HERE
          iis_site { '#{site_name}':
            ensure          => 'started',
            physicalpath    => 'C:\\inetpub\\basic',
            applicationpool => 'DefaultAppPool',
          }
          iis_application { '#{app_name}':
            ensure       => 'present',
            sitename     => '#{site_name}',
            physicalpath => 'C:\\inetpub\\basic',
          }
        HERE

        it_behaves_like 'an idempotent resource', manifest
      end

      context 'when puppet resource is run' do
        let(:result) { on(default, puppet('resource', 'iis_application', "#{site_name}\\\\#{app_name}")) }

        include_context 'with a puppet resource run'# do

        it "iis_application is absent" do
        
          [
            'physicalpath', 'C:\inetpub\basic',
            'applicationpool', 'DefaultAppPool',
          ].each_slice(2) do | key, value |
            puppet_resource_should_show(key, value, result)
          end
        end

        context 'when case is changed in a manifest' do
          manifest = <<-HERE
              iis_application { '#{app_name}':
                ensure       => 'present',
                sitename     => '#{site_name}',
                # Change the capitalization of the T to see if it breaks.
                physicalpath => 'C:\\ineTpub\\basic',
              }
            HERE

          it 'runs with no changes' do
            execute_manifest(manifest, catch_changes: true)
          end
        end
      end

      after(:all) do
        remove_app(app_name)
        remove_all_sites
      end
    end

    context 'with virtual_directory' do
      site_name = SecureRandom.hex(10).to_s
      app_name = SecureRandom.hex(10).to_s
      before(:all) do
        create_site(site_name, true)
        create_path('C:\inetpub\vdir')
        create_virtual_directory(site_name, app_name, 'C:\inetpub\vdir')
      end

      describe 'applies the manifest twice' do
        manifest = <<-HERE
          iis_application { '#{site_name}\\#{app_name}':
            ensure            => 'present',
            virtual_directory => 'IIS:\\Sites\\#{site_name}\\#{app_name}',
          }
        HERE

        it_behaves_like 'an idempotent resource', manifest
      end

      context 'when puppet resource is run' do
        let(:result) { on(default, puppet('resource', 'iis_application', "#{site_name}\\\\#{app_name}")) } 
        
        include_context 'with a puppet resource run'

        it "iis_application is absent" do
          # result = on(default, puppet('resource', 'iis_application', "#{site_name}\\\\#{app_name}"))
          [
            'physicalpath', 'C:\inetpub\vdir',
            'applicationpool', 'DefaultAppPool',
          ].each_slice(2) do | key, value |
            puppet_resource_should_show(key, value, result)
          end
        end
      end

      # it 'removes app' do
      #   remove_app(app_name)
      #   remove_all_sites
      # end
      after(:all) do
        remove_app(app_name)
        remove_all_sites
      end
    end

    context 'with nested virtual directory' do
      site_name = SecureRandom.hex(10).to_s
      app_name = SecureRandom.hex(10).to_s
      before(:all) do
        create_site(site_name, true)
        create_path("c:\\inetpub\\wwwroot\\subFolder\\#{app_name}")
      end

      describe 'applies the manifest twice' do
        manifest = <<-HERE
          iis_application{'subFolder/#{app_name}':
            ensure => 'present',
            applicationname => 'subFolder/#{app_name}',
            physicalpath => 'c:\\inetpub\\wwwroot\\subFolder\\#{app_name}',
            sitename => '#{site_name}'
          }
        HERE

        it_behaves_like 'an idempotent resource', manifest
      end

      describe 'application validation' do
        it 'creates the correct application' do
          result = on(default, puppet('resource', 'iis_application', "#{site_name}\\\\subFolder/#{app_name}"))
          expect(result.stdout).to match(/iis_application { '#{site_name}\\subFolder\/#{app_name}':/)
          expect(result.stdout).to match(%r{ensure\s*=> 'present',})
        end
      end

      after(:all) do
        remove_app(app_name)
        remove_all_sites
      end
    end

    context 'with nested virtual directory and single namevar' do
      site_name = SecureRandom.hex(10).to_s
      app_name = SecureRandom.hex(10).to_s
      before(:all) do
        create_site(site_name, true)
        create_path("c:\\inetpub\\wwwroot\\subFolder\\#{app_name}")
      end

      describe 'applies the manifest twice' do
        manifest = <<-HERE
          iis_application{'subFolder/#{app_name}':
            ensure => 'present',
            physicalpath => 'c:\\inetpub\\wwwroot\\subFolder\\#{app_name}',
            sitename => '#{site_name}'
          }
        HERE

        it_behaves_like 'an idempotent resource', manifest
      end

      describe 'application validation' do
        it 'creates the correct application' do
          result = on(default, puppet('resource', 'iis_application', "#{site_name}\\\\subFolder/#{app_name}"))
          expect(result.stdout).to match(/iis_application { '#{site_name}\\subFolder\/#{app_name}':/)
          expect(result.stdout).to match(%r{ensure\s*=> 'present',})
        end
      end

      after(:all) do
        remove_app(app_name)
        remove_all_sites
      end
    end

    context 'with forward slash virtual directory name format' do
      context 'with a leading slash' do
        site_name = SecureRandom.hex(10).to_s
        app_name = SecureRandom.hex(10).to_s
        before(:all) do
          create_site(site_name, true)
          create_path("c:\\inetpub\\wwwroot\\subFolder\\#{app_name}")
        end

        describe 'applies the manifest twice' do
          manifest = <<-HERE
            iis_application{'subFolder/#{app_name}':
              ensure => 'present',
              applicationname => '/subFolder/#{app_name}',
              physicalpath => 'c:\\inetpub\\wwwroot\\subFolder\\#{app_name}',
              sitename => '#{site_name}'
            }
          HERE

          it_behaves_like 'an idempotent resource', manifest
        end

        after(:all) do
          remove_app(app_name)
          remove_all_sites
        end
      end
    end

    context 'with backward slash virtual directory name format' do
      site_name = SecureRandom.hex(10).to_s
      app_name = SecureRandom.hex(10).to_s
      before(:all) do
        create_site(site_name, true)
        create_path("c:\\inetpub\\wwwroot\\subFolder\\#{app_name}")
      end

      describe 'applies the manifest twice' do
        manifest = <<-HERE
            iis_application{'subFolder\\#{app_name}':
              ensure => 'present',
              applicationname => 'subFolder/#{app_name}',
              physicalpath => 'c:\\inetpub\\wwwroot\\subFolder\\#{app_name}',
              sitename => '#{site_name}'
            }
        HERE

        it_behaves_like 'an idempotent resource', manifest
      end

      after(:all) do
        remove_app(app_name)
        remove_all_sites
      end
    end

    context 'with two level nested virtual directory' do
      site_name = SecureRandom.hex(10).to_s
      app_name = SecureRandom.hex(10).to_s
      before(:all) do
        create_site(site_name, true)
        create_path("c:\\inetpub\\wwwroot\\subFolder\\sub2\\#{app_name}")
      end

      describe 'applies the manifest twice' do
        manifest = <<-HERE
          iis_application{'subFolder/sub2/#{app_name}':
            ensure => 'present',
            applicationname => 'subFolder/sub2/#{app_name}',
            physicalpath => 'c:\\inetpub\\wwwroot\\subFolder\\sub2\\#{app_name}',
            sitename => '#{site_name}'
          }
        HERE

        it_behaves_like 'an idempotent resource', manifest
      end

      describe 'application validation' do
        let(:result) { on(default, puppet('resource', 'iis_application', "#{site_name}\\\\subFolder/sub2/#{app_name}")) }
        it 'creates the correct application' do
          expect(result.stdout).to match(/iis_application { '#{site_name}\\subFolder\/sub2\/#{app_name}':/)
          expect(result.stdout).to match(%r{ensure\s*=> 'present',})
        end
      end

      after(:all) do
        remove_app(app_name)
        remove_all_sites
      end
    end
  end

  context 'when setting' do
    skip 'sslflags - blocked by MODULES-5561' do
      site_name = SecureRandom.hex(10).to_s
      app_name = SecureRandom.hex(10).to_s
      site_hostname = 'www.puppet.local'
      before(:all) do
        create_site(site_name, true)
        create_path('C:\inetpub\wwwroot')
        create_path('C:\inetpub\modify')
        create_app(site_name, app_name, 'C:\inetpub\wwwroot')
        @certificate_hash = create_selfsigned_cert('www.puppet.local').downcase
      end

    describe 'applies the manifest twice' do
      manifest = <<-HERE
        iis_site { '#{site_name}':
          ensure          => 'started',
          physicalpath    => 'C:\\inetpub\\wwwroot',
          applicationpool => 'DefaultAppPool',
          bindings        => [
            {
              'bindinginformation'   => '*:80:#{site_hostname}',
              'protocol'             => 'http',
            },
            {
              'bindinginformation'   => '*:443:#{site_hostname}',
              'protocol'             => 'https',
              'certificatestorename' => 'MY',
              'certificatehash'      => '#{@certificate_hash}',
              'sslflags'             => 0,
            },
          ],
        }
        iis_application { '#{app_name}':
          ensure       => 'present',
          sitename     => '#{site_name}',
          physicalpath => 'C:\\inetpub\\modify',
          sslflags     => ['Ssl','SslRequireCert'],
        }
      HERE

      it_behaves_like 'an idempotent resource', manifest
    end
  end

    describe 'authenticationinfo' do
      site_name = SecureRandom.hex(10).to_s
      app_name = SecureRandom.hex(10).to_s
      before(:all) do
        create_path('C:\inetpub\wwwroot')
        create_path('C:\inetpub\auth')
        create_site(site_name, true)
        create_app(site_name, app_name, 'C:\inetpub\auth')
      end

      describe 'applies the manifest twice' do
        manifest = <<-HERE
          iis_application { '#{app_name}':
            ensure       => 'present',
            sitename     => '#{site_name}',
            physicalpath => 'C:\\inetpub\\auth',
            authenticationinfo => {
              'basic'     => true,
              'anonymous' => false,
            },
          }
        HERE

        it_behaves_like 'an idempotent resource', manifest
      end
    end

    describe 'applicationpool' do
      site_name = SecureRandom.hex(10).to_s
      app_name = SecureRandom.hex(10).to_s
      before(:all) do
        create_path('C:\inetpub\wwwroot')
        create_path('C:\inetpub\auth')
        create_site(site_name, true)
        create_app(site_name, app_name, 'C:\inetpub\auth')
        create_app_pool('foo_pool')
      end

      describe 'applies the manifest twice' do
        manifest = <<-HERE
          iis_application { '#{app_name}':
            ensure       => 'present',
            sitename     => '#{site_name}',
            physicalpath => 'C:\\inetpub\\auth',
            applicationpool => 'foo_pool'
          }
        HERE

        it_behaves_like 'an idempotent resource', manifest
      end
    end
  end

  context 'when removing an application' do
    site_name = SecureRandom.hex(10).to_s
    app_name = SecureRandom.hex(10).to_s
    before(:all) do
      create_site(site_name, true)
      create_path('C:\inetpub\remove')
      create_virtual_directory(site_name, app_name, 'C:\inetpub\remove')
      create_app(site_name, app_name, 'C:\inetpub\remove')
    end

    describe 'applies the manifest twice' do
      manifest = <<-HERE
        iis_application { '#{app_name}':
          ensure       => 'absent',
          sitename     => '#{site_name}',
          physicalpath => 'C:\\inetpub\\remove',
        }
      HERE

      it_behaves_like 'an idempotent resource', manifest
    end

    context 'when puppet resource is run' do
      let(:result) { on(default, puppet('resource', 'iis_application', "#{site_name}\\\\#{app_name}")) }
      include_context 'with a puppet resource run'
      it "iis_application is absent" do
        result = on(default, puppet('resource', 'iis_application', "#{site_name}\\\\#{app_name}"))
        puppet_resource_should_show('ensure', 'absent', result)
      end
    end

    after(:all) do
      remove_app(app_name)
    end
  end

  context 'with multiple sites with same application name' do
    site_name = SecureRandom.hex(10).to_s
    site_name2 = SecureRandom.hex(10).to_s
    app_name = SecureRandom.hex(10).to_s
    before(:all) do
      remove_all_sites
      create_path("C:\\inetpub\\#{site_name}\\#{app_name}")
      create_path("C:\\inetpub\\#{site_name2}\\#{app_name}")
    end

    describe 'applies the manifest twice' do
      manifest = <<-HERE
        iis_site { '#{site_name}':
          ensure          => 'started',
          physicalpath    => 'C:\\inetpub\\#{site_name}',
          applicationpool => 'DefaultAppPool',
          bindings        => [
          {
            'bindinginformation' => '*:8081:',
            'protocol'           => 'http',
          }]
        }
        iis_application { '#{site_name}\\#{app_name}':
          ensure            => 'present',
          sitename        => '#{site_name}',
          physicalpath => 'C:\\inetpub\\#{site_name}\\#{app_name}',
        }
        iis_site { '#{site_name2}':
          ensure          => 'started',
          physicalpath    => 'C:\\inetpub\\#{site_name2}',
          applicationpool => 'DefaultAppPool',
        }
        iis_application { '#{site_name2}\\#{app_name}':
          ensure            => 'present',
          sitename        => '#{site_name2}',
          physicalpath => 'C:\\inetpub\\#{site_name2}\\#{app_name}',
        }
        HERE

      it_behaves_like 'an idempotent resource', manifest
    end

    context 'when puppet resource is run' do
      let(:result) { on(default, puppet('resource', 'iis_application', "#{site_name}\\\\#{app_name}")) }
let(:result2) { on(default, puppet('resource', 'iis_application', "#{site_name2}\\\\#{app_name}")) }


    it 'contains two sites with the same app name' do
      # on(default, puppet('resource', 'iis_application', "#{site_name}\\\\#{app_name}")) do |result|
        expect(result.stdout).to match(%r{#{site_name}\\#{app_name}})
        expect(result.stdout).to match(%r{ensure\s*=> 'present',})
        expect(result.stdout).to match %r{C:\\inetpub\\#{site_name}\\#{app_name}}
        expect(result.stdout).to match %r{applicationpool\s*=> 'DefaultAppPool'}
      end
      # on(default, puppet('resource', 'iis_application', "#{site_name2}\\\\#{app_name}")) do |result|
      it 'contains two sites with the same app name' do
        expect(result2.stdout).to match(%r{#{site_name2}\\#{app_name}})
        expect(result2.stdout).to match(%r{ensure\s*=> 'present',})
        expect(result2.stdout).to match %r{C:\\inetpub\\#{site_name2}\\#{app_name}}
        expect(result2.stdout).to match %r{applicationpool\s*=> 'DefaultAppPool'}
      end
    end

    after(:all) do
      remove_app(app_name)
      remove_all_sites
    end
  end
end