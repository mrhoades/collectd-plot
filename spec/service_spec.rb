require 'spec_helper'

describe 'the service' do
  before :all do
    r = CollectdPlot::RRDRemote.redis_conn
    r.keys('rrd_remote.*').each { |k| r.del k }
  end


  context 'when running on a persistence shard' do

    before :each do
      CollectdPlot::Config.clear!
      CollectdPlot::Config.from_file("#{File.dirname(__FILE__)}/fixtures/config.json")
      CollectdPlot::Config.proxy = false
    end

    it 'should list hosts' do
    JSON.parse(get('/hosts.json').body).should == ['host_a', 'host_b']
    end

    it 'should list metrics for a host' do
      JSON.parse(get('/hosts/host_a.json').body).should ==  {
        "df-root" => ["df_complex-free", "df_complex-reserved", "df_complex-used"],
        "load" => ["load"],
        "memory" => ["memory-buffered", "memory-cached", "memory-free", "memory-used"]
      }
    end

    it 'should give an empty hash for unknown hosts' do
      JSON.parse(get('/hosts/foobar.json').body).should == {}
    end

    it 'should return the rrd file for a given metric' do
      actual = get('/hosts/host_a/metric/memory/instance/memory-free/rrd').body
      expected = File.read("#{File.dirname(__FILE__)}/fixtures/rrd/host_a/memory/memory-free.rrd")
      actual.should == expected
    end

    it 'should return rrd data for a host and time interval' do
      pending 'TODO'
    end

    it 'returns rrd data for a metric' do
      start = 1335739560
      stop = start + 1000
      pending 'TODO'
    end

  end


  context 'when acting as a proxy' do

    before :each do
      CollectdPlot::Config.clear!
      CollectdPlot::Config.from_file("#{File.dirname(__FILE__)}/fixtures/config.json")
      CollectdPlot::Config.proxy = true

      CollectdPlot::RRDRemote.stub!(:http_get).with("192.168.50.16/hosts.json").and_return(['baz', 'bam'])
      CollectdPlot::RRDRemote.stub!(:http_get).with("192.168.50.17/hosts.json").and_return(['bar', 'foo'])
    end

    it 'should return the union of the hosts on all shards' do
      JSON.parse(get('/hosts.json').body).sort.should == ['bam', 'bar', 'baz', 'foo']
    end

    it 'should correctly map hosts to shards' do
      CollectdPlot::RRDRemote.shard_for_host('bam').should == "192.168.50.16"
      CollectdPlot::RRDRemote.shard_for_host('foo').should == "192.168.50.17"
      lambda { CollectdPlot::RRDRemote.host_for_shard('does_not_exist') }.should raise_error
    end

    it 'should retrieve rrd files from the appropriate shard for a host' do
      pending 'TODO'
    end

  end



  it 'sandbox' do
    pending 'sandbox'
#    get '/sandbox'
  end

end
