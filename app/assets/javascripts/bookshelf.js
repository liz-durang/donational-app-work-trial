document.addEventListener('turbolinks:load', function () {

  	var $books = $( '.book-list .book' ), booksCount = $books.length;

		$books.each( function() {
			var $book = $( this ),
				$other = $books.not( $book ),
				$parent = $book.parent(),
				$page = $book.children( '.book-page' ),
				$bookview = $parent,
				$content = $page.children( '.book-content' ), current = 0;

			$bookview.on( 'click', function() {
				var $this = $( this );

				$other.data( 'opened', false ).removeClass( 'book-viewinside' ).parent().css( 'z-index', 0 ).find( 'button.book-bookview' ).removeClass( 'book-active' );
				if( !$other.hasClass( 'book-viewback' ) ) {
					$other.addClass( 'book-bookdefault' );
				}

				if( $book.data( 'opened' ) ) {
					$this.removeClass( 'book-active' );
					$book.data( { opened : false, flip : false } ).removeClass( 'book-viewinside' ).addClass( 'book-bookdefault' );
				}
				else {
					$this.addClass( 'book-active' );
					$book.data( { opened : true, flip : false } ).removeClass( 'book-viewback book-bookdefault' ).addClass( 'book-viewinside' );
					$parent.css( 'z-index', booksCount );
					current = 0;
					$content.removeClass( 'book-content-current' ).eq( current ).addClass( 'book-content-current' );
				}

			} );

			if( $content.length > 1 ) {

				var $navPrev = $( '<span class="book-page-prev">&lt;</span>' ),
					$navNext = $( '<span class="book-page-next">&gt;</span>' );

				$page.append( $( '<nav></nav>' ).append( $navPrev, $navNext ) );

				$navPrev.on( 'click', function() {
					if( current > 0 ) {
						--current;
						$content.removeClass( 'book-content-current' ).eq( current ).addClass( 'book-content-current' );
					}
					return false;
				} );

				$navNext.on( 'click', function() {
					if( current < $content.length - 1 ) {
						++current;
						$content.removeClass( 'book-content-current' ).eq( current ).addClass( 'book-content-current' );
					}
					return false;
				} );

			}

		} );
});
