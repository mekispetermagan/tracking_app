// Miscellaneous utility tools:
// removeChildNodes: empties a dom element
// Timer: handles timeouts and intervals
// Random: randint, choice, and other methods

// Removes the last child node of a dom element until
// there remains none
removeChildNodes = (container) => {
  while (container.firstChild) {
    container.removeChild(container.lastChild);
  }
}

// Methods:
// delay: timeout without danger of accumulation
// repeat: interval for a finite number of times,
//   no accumulation
// forever: infinite repeat, no accumulation
// sleep: delay without action; to be used in async context
class Timer {
  constructor() {
    this.timeout = null;
    this.interval = null;
  }

  delay(fn, duration) {
    clearTimeout(this.timeout);
    this.timeout = setTimeout(fn, duration);
  }

  repeat(fn, n, interval) {
    clearInterval(this.interval);
    let counter = 0;
    this.interval = setInterval(() => {
      if (counter < n) {
        fn();
        counter++;
      } else {
        clearInterval(this.interval);
      }
    }, interval);
  }

  forever(fn, interval) {
    clearInterval(this.interval);
    this.interval = setInterval(fn, interval);
  }


  sleep(duration) {
    return new Promise(resolve => setTimeout(resolve, duration));
  }

  clear() {
    clearTimeout(this.timeout);
    clearInterval(this.interval);
  }
}

// Methods:
// - randRange: random integer between a lower and an 
//   upper limit, including lower and excluding upper
// - randInt: like randRange, but including upper
// - diceRoll: random integer between 1 and 6
// - coinFlip: random integer between 1 and 2
// - choice: chooses a random item from an array
// - choiceExcept: like choice, but excluding items 
//   of another array
// - multiChoice: chooses multiple items from an array
// - multiChoiceExcept: chooses multiple items, 
//   excluding items of another array
// - shuffle: returns the shuffled copy of an array
// - shuffleInplace: shuffles an array (destructive)
// The clasis taken from another project, some methods 
// may not be used here. 
class Random {
  constructor() {}

  randRange(lower, upper) {
    if (!upper) {
      upper = lower;
      lower = 0;
    }
    return lower + Math.floor(Math.random()*(upper-lower));
  }
  
  randInt(lower, upper)  {
    return this.randRange(lower, upper + 1)
  }
  
  diceRoll() {
    return this.randInt(1, 6);
  }
  
  coinFlip() {
    return this.randInt(1, 2);
  }
  
  choice(seq) {
    return seq[this.randRange(0,seq.length)];
  }

  choiceExcept(seq, seqEx) {
    const isString = (s) => typeof s === 'string' || s instanceof String;; 
    if (isString(seq))           {seq   = seq.split("");};
    if (isString(seqEx))         {seqEx = seqEx.split("");};
    const filteredSeq = seq.filter((x) => !seqEx.includes(x));
    if (filteredSeq.length == 0) {return null;}
    else                         {return this.choice(filteredSeq);}
  }
  
  multiChoice(seq, n) {
    let result = [];
    for (i=0; i<n; i++) {
      item = this.choiceExcept(seq, result);
      result.push(item);
    }
    return result;
  }
  
  multiChoiceExcept(seq, seqEx, n) {
    let result = [];
    for (i=0; i<n; i++) {
      item = this.choiceExcept(seq, result.concat(seqEx));
      result.push(item);
    }
    return result;
  }
  
  swap(seq, i, j) {
    let buffer = seq[i];
    seq[i] = seq[j];
    seq[j] = buffer;
  }
  
  shuffle(seq) {
    let cloneSeq = [...seq];
    let shuffledSeq = [];
    while (0 < cloneSeq.length) {
      let i = this.randRange(0, cloneSeq.length);
      shuffledSeq.push(cloneSeq[i]);
      cloneSeq.splice(i, 1);
    }
    return shuffledSeq;
  }
  
  shuffleInplace(seq) {
    for (let i=0; i<seq.length-1; i++) {
      let j = this.randRange(i+1, seq.length);
      this.swap(seq, i, j);
    }
  }
  
  getVariations(...sequences) {
    const prependItem = (xss, ys) => {
      let result = [];
      for (let xs of xss) {
        for (y of ys) {
          result.push([y].concat(xs));
        }
      }
      return result;
    }
    let result = [[]];
    while (0 < sequences.length) {
      lastOne = sequences.pop();
      result = prependItem(result, lastOne)
    }
    return result;
  }

}
