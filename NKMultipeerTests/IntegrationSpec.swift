import NKMultipeer
import Quick
import Nimble
import RxSwift

public class IntegrationSpec : QuickSpec {

  override public func spec() {

    var disposeBag = DisposeBag()

    describe("two clients") {

      var clientone: CurrentClient?
      var clienttwo: CurrentClient?

      beforeEach {
        clientone = CurrentClient(MockSession())
        clienttwo = CurrentClient(MockSession())
        disposeBag = DisposeBag()
      }

      describe("client two advertises") {

        beforeEach {
          // Advertise and always accept connections
          clienttwo!.advertise()
          >- subscribeNext { (client, respond) in respond(true) }
          >- disposeBag.addDisposable
        }

        it("allows client one to browse for client two") {
          waitUntil { done in
            clientone!.browse()
            >- subscribeNext { clients in
              expect(clients[0].iden.isIdenticalTo(clienttwo!.iden)).to(equal(true))
              done()
            }
            >- disposeBag.addDisposable
            return
          }
          return
        }

        it("clients can connect with eachother") {
          waitUntil { done in
            let connection = clientone!.connect(clienttwo!) >- variable

            connection
            >- subscribeNext { expect($0).to(beTrue()) }
            >- disposeBag.addDisposable

            connection
            >- subscribeCompleted { done() }
            >- disposeBag.addDisposable
          }
        }

        describe("clients are connected") {

          beforeEach {
            waitUntil { done in
              clientone!.connect(clienttwo!)
              >- subscribeCompleted { done() }
              >- disposeBag.addDisposable
            }
          }

          it("allows client two to disconnect") {
            waitUntil { done in
              expect(count(clientone!.connections)).to(equal(1))
              clienttwo!.disconnect()
              >- subscribeCompleted {
                expect(count(clientone!.connections)).to(equal(0))
                expect(count(clienttwo!.connections)).to(equal(0))
                done()
              }
              >- disposeBag.addDisposable
            }
          }

          it("allows client one to disconnect") {
            waitUntil { done in
              expect(count(clienttwo!.connections)).to(equal(1))
              clientone!.disconnect()
              >- subscribeCompleted {
                expect(count(clientone!.connections)).to(equal(0))
                expect(count(clienttwo!.connections)).to(equal(0))
                done()
              }
              >- disposeBag.addDisposable
            }
          }

          it("lets clients send strings to eachother") {
            waitUntil { done in
              clientone!.send(clienttwo!, "hello")
              clienttwo!.receive()
              >- subscribeNext { (string: String) in
                expect(string).to(equal("hello"))
                done()
              }
              >- disposeBag.addDisposable
            }
          }

          it("lets clients send resource urls to each other") {
            waitUntil { done in
              let url = NSBundle(forClass: self.dynamicType).URLForResource("Data", withExtension: "txt")
              clientone!.send(clienttwo!, name: "txt file", url: url!)
              clienttwo!.receive()
              >- subscribeNext { (name: String, url: NSURL) in
                expect(name).to(equal("txt file"))
                let contents = NSString(data: NSData(contentsOfURL: url)!, encoding: NSUTF8StringEncoding)
                expect(url).to(equal("hello there this is random data"))
                done()
              }
              >- disposeBag.addDisposable
            }
          }

        }

      }

    }

  }

}
