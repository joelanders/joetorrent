#joetorrent
work-in-progress bittorrent client

Here's an overview of what it does so far:

````ruby
# load piece information from torrent file.
mi = Metainfo.from_file 'boa.torrent'

# do a tracker announce to get list of peers for this file.
mi.tracker.announce

# ignore that list of peers for now (because I can't get a socket to
# connect to a remote peer...NAT issues?) and connect to my local
# instance of Transmission, which is seeding boa.torrent
pr = Peer.new '127.0.0.1', 51413, mi

# open the tube
pr.connect_socket

# hi, I speak BitTorrent, my name is... and I'm looking for...
pr.do_handshake

# here are the pieces I have (none)
pr.socket.write Message.bitfield([], mi.num_pieces)

# right now, this logs messages and responds to keepalives
pr.start_event_loop

# wait a tick and check the messages...
# first message is the received handshake.
# second message is a bitfield with the pieces that the Transmission
#   client has. 0x05 is the message ID, and the rest is 1s because
#   the Transmission client has every piece.
# third message (0x01) is unchoke, indicating that the Transmission
#   client is ready to send me data.
pr.recd_messages
=> [[2013-10-26 16:42:08 -0700,
     "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x10\x00\x05BCz\x1A\xC2\xB9fz\xBD\x85xt\xD01v\xD1\xFA\xB6t\xF6-TR2820-9dx8c364jfe8"],
    [2013-10-26 16:42:09 -0700, "\x05\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x80"],
    [2013-10-26 16:42:15 -0700, "\x01"]]
    
# please send me the data starting at piece 0, index 0, and going
#   on for 16 bytes. (normally this would be 2**14 bytes)
pr.socket.write Message.request 0, 0, 2**4 

# check our messages again, and see that we got the data!
# "\a" is 0x07, which is the message id for a piece.
# the next 8 zero bytes are the piece # and index.
# after that is the beginning of the PDF we were looking for!
pr.recd_messages.last
=> [2013-10-26 16:42:56 -0700,
    "\a\x00\x00\x00\x00\x00\x00\x00\x00%PDF-1.3\n%\xE7\xF3\xCF\xD3\n2"]
````


GPLv3 license because I feel like it.
