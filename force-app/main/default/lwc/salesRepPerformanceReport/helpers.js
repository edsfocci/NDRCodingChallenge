const helpers = {
    sortBy: (field, reverse) => {
        const key = x => x[field];

        return (a, b) => {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    },

    addDays: (oldDate, days) => {
        const newDate = new Date(oldDate.getTime());
        newDate.setDate(newDate.getDate() + days);

        return newDate;
    }
};

export default helpers;
