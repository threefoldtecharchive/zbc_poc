import argparse
from datetime import datetime
import logging
from os.path import dirname, isdir
import random
import requests


def generate_data(count):
    r = requests.get("https://www.mit.edu/~ecprice/wordlist.100000")
    words = r.text.split("\n")
    data = {}
    
    for x in range(count):
        key = words[min(len(words), int(random.random()*len(words)))]
        val = words[min(len(words), int(random.random()*len(words)))]
        data[key] = val
        
    return data  


def main():
    parser = argparse.ArgumentParser(
        description="This tool allows you to start a multi node network.")

    parser.add_argument("--address", required=False, type=str, default="localhost:26657",
                        help="The address to connect to")
    parser.add_argument("--log-file", required=False, type=str, default="stress_test.log",
                        help="The log file where to put the results of the commands")
    parser.add_argument("--amount", required=False, type=int, default=10000,
                        help="The amount of transactions to deliver")
    parser.add_argument("--type", required=False, type=str, default="commit", 
                        help="the type of transaction: commit, sync or async")
    parser.add_argument('--verbose', action="store_true",
                        help="increase output verbosity")
    args = parser.parse_args()
    
    assert(args.type in ["commit", "sync", "async"])

    logging.basicConfig(
        format="%(asctime)s %(levelname)s %(message)s", level=logging.DEBUG if args.verbose else logging.INFO)
    logging.info("Generating data")
    data = generate_data(args.amount)
    logging.info("Done")
    x = 0
    start = datetime.now()
    futures = {}
    for key, value in data.items():
        x += 1
        if not args.verbose and x % 100 == 0:
            print(".", end="", flush=True)
        url = f"http://{args.address}/broadcast_tx_{args.type}?tx=\"{key}={value}\""
        logging.debug("%s", url) 
        r = requests.get(url)
        assert(r.ok)
        logging.debug(r.text)
        
    if not args.verbose:
        print("")

    elapsed_time = datetime.now()-start
    logging.info("Finished stress test in %s (~%s transactions/sec)", elapsed_time, int(args.amount / elapsed_time.total_seconds()))


if __name__ == "__main__":
    main()
