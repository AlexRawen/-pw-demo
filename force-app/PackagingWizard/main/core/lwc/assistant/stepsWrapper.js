export default class StepsWrapper {
    search(field, query) {
        return this.list.filter(item => item[field] === query);
    }
    getByName(name) {
        const search = this.search("name", name);
        return search.length > 0 ? search[0] : { inx: 0, name: null };
    }
    getById(id) {
        const search = this.search("inx", id);
        return search.length > 0 ? search[0] : { inx: 0, name: null };
    }
    getNext(name) {
        const curId = this.getByName(name);
        return this.getById(curId + 1);
    }
    getPrev(name) {
        const curId = this.getByName(name);
        return this.getById(curId - 1);
    }
    updateAvailability() {
        this.getByName("heroku").disable(
            !this.list.slice(0, this.getByName("heroku").inx - 1).every(item => item.valid)
        );
    }
    get sumProgress() {
        const percentEachStep = 100 / (this.length || 1);
        const sum =
            this.length > 0
                ? Math.floor(
                      this.list
                          .map(step => {
                              return (step.progress / 100) * percentEachStep;
                          })
                          .reduce((num, total) => num + total)
                  )
                : 0;
        return { number: sum, percent: `${sum}%`, style: `width: ${sum}%;` };
    }
    get length() {
        return this.list.length;
    }
    get namedList() {
        return this.list.reduce(function(result, item, index, array) {
            result[item.name] = item;
            return result;
        }, {});
    }
    constructor(list) {
        this.list = list || [];
    }
}
