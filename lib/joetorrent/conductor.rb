class Conductor
  attr_accessor :tracker
  def initialize tracker
    @tracker = tracker
  end
  def re_adjust
    # when not seeding
      # get top four interested peers from whom we DL the fastest
      # get top interested peer to whom we UL the fastest
      # unchoke fastest 4 of those 5
      # unchoke uninterested peers with faster UL rates
    # when seeding
      # unchoke top four interested peers to whom we UL the fastest
    # pick some random leecher regardless of speed to be one of the four leechers?
  def peers
    tracker.peers
  end
  def interested_peers
    peers.select {|peer| peer.peer_interested?}
  end
  def top_four_downloaders
    interested_peers.sort_by {|peer| from_rate}[0...4]
  end
end
